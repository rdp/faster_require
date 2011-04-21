$: << '.'
$: << 'files'
if true
  require 'gem_after.rb'
else
 p 'warning not using faster'
 require 'rubygems'
end
require 'active_support'
raise 'poor acctive support' unless ActiveSupport::Inflector::Inflections.instance.plurals.length > 0
# d:/Ruby192/lib/ruby/gems/1.9.1/gems/diff-lcs-1.1.2/lib/diff/lcs/callbacks.rb:53: warning: already initialized constant SequenceCallbacks
require 'action_pack'
require 'action_pack'

# reproduce warning: already initialized constant JS_ESCAPE_MAP