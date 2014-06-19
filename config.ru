require 'rubygems'
require 'sinatra'
require File.expand_path '../open311.rb', __FILE__

set :public, 'public'

run Open311App.new