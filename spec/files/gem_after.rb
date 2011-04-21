$: << '.'

require '../lib/faster_require.rb'
require 'rubygems'
Gem::Specification

raise if FastRequire.already_loaded.to_a.flatten.grep(/files\/b.rb/).length > 0
require 'files/b.rb'
raise if(require 'files/b.rb')
raise 'lacking b.rb ' + FastRequire.already_loaded.to_a.join(' ') unless FastRequire.already_loaded.to_a.flatten.grep(/files\/b.rb/).length > 0
