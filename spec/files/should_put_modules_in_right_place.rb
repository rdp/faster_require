require 'rubygems'
require File.dirname(__FILE__) + "/../../lib/faster_require.rb"
require 'rspec'
a = RSpec
raise 'bad' if FastRequire.constants.grep(/spec/i).length > 0
