require File.expand_path(File.dirname(__FILE__) + "/../../lib/faster_require.rb")
require 'rubygems'
require 'rack'
require 'rack/mount/utils'
::Regin::Parser # an autoload of death... 
#rack-mount (0.6.14)