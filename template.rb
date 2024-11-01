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