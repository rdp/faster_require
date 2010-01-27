require '../lib/fast_require'
require 'rubygems'
Gem::Specification
raise if FastRequire.already_loaded.to_a.flatten.grep /files\/b.rb/
require 'files/b.rb'
require 'files/b.rb'
raise unless FastRequire.already_loaded.to_a.flatten.grep /files\/b.rb/
raise 'I dont trust this'