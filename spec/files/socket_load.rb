$: << '.'

require '../lib/faster_require.rb'
raise if FastRequire.already_loaded.to_a.flatten.grep(/files\/b.rb/).length > 0
require 'socket'
TCPSocket
require 'stringio'
StringIO
raise 'lacking socket ' + FastRequire.already_loaded.to_a.join(' ') unless FastRequire.already_loaded.to_a.flatten.grep(/socket/).length > 0
raise 'lacking stringio ' + FastRequire.already_loaded.to_a.join(' ') unless FastRequire.already_loaded.to_a.flatten.grep(/stringio/).length > 0
