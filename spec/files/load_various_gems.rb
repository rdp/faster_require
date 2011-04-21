$: << '.'
$: << 'files'
if true
  require 'gem_after.rb'
else
  p 'warning not using faster require'
  require 'rubygems'
end
require 'ruby-debug'
require 'rspec'
# d:/Ruby192/lib/ruby/gems/1.9.1/gems/diff-lcs-1.1.2/lib/diff/lcs/callbacks.rb:53: warning: already initialized constant SequenceCallbacks