$: << '.'

require '../lib/faster_require.rb'
require 'rubygems'
Gem::Specification

raise if FastRequire.already_loaded.to_a.flatten.grep(/files\/b.rb/).length > 0
p 'about to require b'
#require 'ruby-debug' 
#debugger
require 'files/b.rb'
p 'done requiring b'
raise if(require 'files/b.rb')
raise 'lacking b.rb ' + FastRequire.already_loaded.to_a.join(' ') unless FastRequire.already_loaded.to_a.flatten.grep(/files\/b.rb/).length > 0
