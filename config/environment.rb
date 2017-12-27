# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!
require 'zebra_printer'
require 'bantu_soundex'
require 'csv'
require 'json'
require 'misc'