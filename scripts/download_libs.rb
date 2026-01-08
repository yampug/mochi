#!/usr/bin/env ruby

require 'open-uri'
require 'fileutils'
require 'rbconfig'

BASE_URL = 'https://storage.googleapis.com/mochi-libs'
LIBS_DIR = File.expand_path('../../fragments/libs', __FILE__)

def detect_platform
  host_os = RbConfig::CONFIG['host_os']

  case host_os
  when /darwin|mac os/
    'darwin'
  when /linux/
    'linux'
  when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
    'windows'
  else
    raise "Unsupported platform: #{host_os}"
  end
end

def detect_architecture
  host_cpu = RbConfig::CONFIG['host_cpu']

  case host_cpu
  when /x86_64|x64|amd64/
    'x86_64'
  when /aarch64|arm64/
    'aarch64'
  when /arm/
    'arm'
  else
    raise "Unsupported architecture: #{host_cpu}"
  end
end

def download_and_extract(platform, arch)
  filename = "#{platform}_#{arch}.zip"
  url = "#{BASE_URL}/#{filename}"
  zip_path = File.join(LIBS_DIR, filename)

  puts "Detected platform: #{platform}"
  puts "Detected architecture: #{arch}"
  puts "Downloading from: #{url}"

  # Ensure libs directory exists
  FileUtils.mkdir_p(LIBS_DIR)

  # Download the file
  begin
    URI.open(url) do |remote_file|
      File.open(zip_path, 'wb') do |local_file|
        local_file.write(remote_file.read)
      end
    end
    puts "Downloaded to: #{zip_path}"
  rescue => e
    puts "Error downloading file: #{e.message}"
    exit 1
  end

  # Extract the zip file using system unzip command
  puts "Extracting files..."
  if system("unzip -o #{zip_path} -d #{LIBS_DIR}")
    puts "Extraction complete!"
  else
    puts "Error extracting file"
    exit 1
  end

  # Clean up the zip file and macOS metadata directory
  File.delete(zip_path) if File.exist?(zip_path)
  FileUtils.rm_rf(File.join(LIBS_DIR, '__MACOSX'))
end

# Allow platform and architecture to be overridden via command line arguments
platform = ARGV[0] || detect_platform
arch = ARGV[1] || detect_architecture

download_and_extract(platform, arch)
