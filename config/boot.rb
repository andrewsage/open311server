# Load dependencies
require 'rubygems'
require 'bundler/setup'
Bundler.require

# Load all modules
["initializers", "../lib", "../app", "../app/models"].each do |m|
  Dir[File.expand_path("../#{m}/*.rb", __FILE__)].each do |file|
    require file
  end
end