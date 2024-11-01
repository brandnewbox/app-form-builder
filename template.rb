require 'open-uri'

def read_file(url)
  URI.open(url).read
rescue OpenURI::HTTPError => e
  puts "Failed to download file: #{e.message}"
  nil
rescue StandardError => e
  puts "Error reading file: #{e.message}" 
  nil
end

form_builder_content = read_file("https://raw.githubusercontent.com/brandnewbox/app-form-builder/master/app_form_builder.rb")

create_file "app/helpers/app_form_builder.rb", form_builder_content
create_file "app/helpers/app_form_builder_helper.rb", <<~RUBY
  module AppFormBuilderHelper
    def app_form_with(*, **, &)
      AppFormBuilder.with_blank_error_proc do
        form_with(*, builder: AppFormBuilder, **, &)
      end
    end
  end
RUBY

if File.exist?("app/controllers/application_controller.rb")
  insert_into_file "app/controllers/application_controller.rb", after: "class ApplicationController < ActionController::Base\n" do
    "\n  default_form_builder AppFormBuilder\n"
  end
end

create_file "config/initializers/blank_form_error_proc.rb", <<~RUBY
  Rails.application.config.action_view.field_error_proc = Proc.new { |tag, instance| tag }
RUBY
