require 'opal'

opal_runtime_javascript = Opal::Builder.build('opal').to_s

runtime_filename = 'devground/opal-runtime.js'

File.open(runtime_filename, 'w') do |file|
  file.write(opal_runtime_javascript)
end

puts "Opal runtime has been successfully compiled to #{runtime_filename}"
