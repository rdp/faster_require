$: << '.'
$:.unshift 'bin'
require File.dirname(File.expand_path(__FILE__)) + '/../../lib/faster_require.rb'
require 'non_dot_rb.rb' # succeed
raise if require 'non_dot_rb' # fails (well, returns false), we think it succeeds, but it in the wrong place, so when we run the second time, it loads the wrong file

# unless my gem is working right