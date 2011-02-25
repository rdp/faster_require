$: << '.'
require 'rubygems'
Gem::Specification

require '../lib/faster_require.rb'

raise if FastRequire.already_loaded.to_a.flatten.grep(/files\/b.rb/).length > 0
require 'files/b.rb'
raise if(require 'files/b.rb')
raise unless  FastRequire.already_loaded.to_a.flatten.grep(/files\/b.rb/).length > 0