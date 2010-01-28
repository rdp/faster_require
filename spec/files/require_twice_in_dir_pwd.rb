require File.dirname(File.expand_path(__FILE__)) + '/../../lib/fast_require.rb'
raise if (require File.dirname(File.expand_path(__FILE__)) + '/../../lib/fast_require.rb') # another test, why not? :)
require 'b.rb'
require 'b'
raise unless FastRequire.require_locs.keys.include?('b.rb') && FastRequire.require_locs.keys.include?('b')

