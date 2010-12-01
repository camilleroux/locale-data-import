require 'rubygems'
require 'bundler'
require 'open-uri'

# Rake task for importing country names from Unicode.org's CLDR repository
# (http://www.unicode.org/cldr/data/charts/summary/root.html).
#
# It parses a HTML file from Unicode.org for given locale and saves the
# Rails' I18n hash in the plugin +locale+ directory
#
# Don't forget to restart the application when you add new locale to load it into Rails!
#
# == Example
#   rake import:locale locale=fr type=territories
#
# The code is deliberately procedural and simple, so it's easily
# understandable by beginners as an introduction to Rake tasks power.
# See http://github.com/joshmh/cldr/tree/master/converter.rb for much more robust solution

namespace :import do

  desc "Import locale data (code and name) for various languages from the Unicode.org CLDR archive. Depends on Hpricot gem."
  task :locale do
    begin
      require 'hpricot'
    rescue LoadError
      puts "Error: Hpricot library required to use this task (import:locale)"
      exit
    end

    # TODO : Implement locale import chooser from CLDR root via Highline

    # Setup variables
    locale = ENV['locale']
    type = ENV['type']
    unless locale && type
      puts "\n[!] Usage: rake import:locale locale=fr type=territories\n\n"
      exit 0
    end
    types = {'territories' => /^namesterritory$/, 'languages' => /^nameslanguage$/}
    unless types.include? type
      puts "\n[!] type must be 'territories' or 'languages'\n\n"
      exit 0
    end

    # ----- Get the CLDR HTML     --------------------------------------------------
    begin
      puts "... getting the HTML file for locale '#{locale}'"
      doc = Hpricot( open("http://www.unicode.org/cldr/data/charts/summary/#{locale}.html") )
    rescue => e
      puts "[!] Invalid locale name '#{locale}'! Not found in CLDR (#{e})"
      exit 0
    end


    # ----- Parse the HTML with Hpricot     ----------------------------------------
    puts "... parsing the HTML file"
    translations = []
    doc.search("//tr").each do |row|
      if row.search("td[@class='n']") &&
         row.search("td[@class='n']").inner_html =~ types[type] &&
         (type != "territories" || row.search("td[@class='g']").inner_html =~ /^[A-Z]{2}$/) &&
          (type != "languages" || row.search("td[@class='g']").inner_html =~ /^[a-zA-Z_]+$/)
        code   = row.search("td[@class='g']").inner_text
        #code   = code[-code.size, 2]
        name   = row.search("td[@class='v']").inner_text
        translations << { :code => code.to_sym, :name => name.to_s }
        print " ... #{name}"
      end
    end


    # ----- Prepare the output format     ------------------------------------------
    output =<<HEAD
{ :#{locale} => {

    :#{type} => {
HEAD
    translations.each do |translation|
      output << "\t\t\t:#{translation[:code]} => \"#{translation[:name]}\",\n"
    end
    output <<<<TAIL
    }

  }
}
TAIL


    # ----- Write the parsed values into file      ---------------------------------
    puts "\n... writing the output"
    filename = File.join(Rails.root, 'config', 'locales', "#{type}.#{locale}.rb")
    File.open(filename, 'w+') { |f| f << output }
    puts "\n---\nWritten values for the '#{locale}' into file: #{filename}\n"
    # ------------------------------------------------------------------------------
  end

end