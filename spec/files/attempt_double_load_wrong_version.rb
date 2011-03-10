$FAST_REQUIRE_DEBUG = 1
a = File.dirname(File.expand_path(__FILE__)) + '/../../lib/faster_require.rb'
load a
FastRequire::VERSION='fake'
load a
