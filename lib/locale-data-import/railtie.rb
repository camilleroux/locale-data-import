require 'locale-data-import'
require 'rails'
module MyLocaleDataImport
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/locale-data-import.rake"
    end
  end
end