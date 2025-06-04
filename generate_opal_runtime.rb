require 'opal'

# Build the full Opal runtime and corelib
# Use 'opal/mini' for a smaller runtime if you only need basic features.
# For the full runtime including Date, StringScanner, etc., use 'opal'.
opal_runtime_javascript = Opal::Builder.build('opal').to_s

# Define the output filename
runtime_filename = 'devground/opal-runtime.js'

# Write the generated JavaScript to the file
File.open(runtime_filename, 'w') do |file|
  file.write(opal_runtime_javascript)
end

puts "Opal runtime has been successfully compiled to #{runtime_filename}"
