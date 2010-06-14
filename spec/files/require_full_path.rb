require File.dirname(File.expand_path(__FILE__)) + '/../../lib/faster_require.rb'
raise if (require File.dirname(File.expand_path(__FILE__)) + '/../../lib/faster_require.rb') # another test, why not? :)
paths = [File.expand_path('b.rb'), File.expand_path('b')]
paths.each{|p| require p}
paths.each{|p| raise unless FastRequire.require_locs.keys.include?(p)}

