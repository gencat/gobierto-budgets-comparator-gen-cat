module GobiertoBudgets
  module Describable
    extend ActiveSupport::Concern

    module ClassMethods
      def all_descriptions
        @all_descriptions ||= begin
                                h = {}
                                default_path = "./db/data/budget_line_descriptions_#{I18n.default_locale}.yml"
                                raise "Missing default locale file #{default_path}" unless File.file?(default_path)

                                I18n.available_locales.each do |locale|
                                  path = "./db/data/budget_line_descriptions_#{locale}.yml"
                                  unless File.file?(path)
                                    path = default_path
                                  end
                                  h[locale] = YAML.load_file(path)
                                end
                                h
                              end
      end
    end
  end
end
