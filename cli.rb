#!/usr/bin/env ruby
require 'csv'
require 'geocoder'
require 'optparse'

# Validate email format
def valid_email?(email)
  email =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
end

# Validate address presence
def valid_address?(address)
  !address.nil? && !address.strip.empty?
end

# Validate location/postcode pair
def valid_location?(location, postcode)
  !location.nil? && !location.strip.empty? && !postcode.nil? && !postcode.strip.empty?
end

# Fetch GEO coordinates for a given address
def fetch_coordinates(address)
  Geocoder.search(address).first&.coordinates
end

# Validate and enhance client information
def process_csv(input_file, output_file = nil)
  output_file ||= 'output.csv' # Use a default output file if not provided

  CSV.open(output_file, 'wb') do |csv_out|
    CSV.foreach(input_file, headers: true) do |row|
      # Skip rows with nil or blank email
      next if row['Email'].to_s.strip.empty?

      # Check for blank first and last name
      next if row['First Name'].nil? || row['Last Name'].nil? || !valid_email?(row['Email'])

      # Check for blank residential or postal addresses
      next unless valid_address?(row['Residential Address Street']) && valid_address?(row['Postal Address Street'])

      # Validate location/postcode pair
      next unless valid_location?(row['Residential Address Locality'], row['Residential Address Postcode']) &&
                  valid_location?(row['Postal Address Locality'], row['Postal Address Postcode'])

      # Fetch GEO coordinates for each row
      coordinates = fetch_coordinates(row['Residential Address Street'])
      next if coordinates.nil?

      # Add the valid row with GEO coordinates to the output CSV
      csv_out << row.fields + coordinates
    end
  end
end

# Command-line interface
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: cli [options]"

  opts.on("--output FILE", "Specify output file") do |file|
    options[:output_file] = file
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

# Process CSV based on command-line options
if ARGV.empty?
  puts "Error: Input CSV file not provided."
  puts "Usage: cli [options] <input_file>"
  exit(1)
end

input_file = ARGV.first
output_file = options[:output_file]

process_csv(input_file, output_file)
