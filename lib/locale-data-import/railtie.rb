require 'locale-data-import'
require 'rails'
module MyLocaleDataImport
  class Railtie < Rails::Railtie
    railtie_name :locate_data_import

    rake_tasks do
      load "tasks/import-tasks.rake"
    end
  end
end