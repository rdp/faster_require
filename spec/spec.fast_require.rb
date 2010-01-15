raise if defined?(FastRequire)
require 'sane'
require 'spec/autorun'
require_relative '../lib/fast_require.rb'

$: << File.dirname(__FILE__)  

describe "faster requires" do
  
  def with_file(filename)
    FileUtils.touch filename + '.rb'
    yield
    FileUtils.rm filename + '.rb'
  end
  
  it "should require files still" do
    with_file('file1') { require 'file1'}    
  end
  
  it "should require .so files still" do
    # ruby-prof gem
    require 'ruby_prof' # .so
  end
  
  it "should add them to $LOADED_FEATURES" do
    with_file('file2') {require 'file2'}
    assert ($LOADED_FEATURES.grep(/file2.rb/)).length > 0
  end
  
  it "should work with and without rubygems, esp. in 1.8"
  
  it "should have a faster require method--faster, my friend, faster!"
  
  it "should save a file" do
    loc = File.expand_path('~/.ruby_fast_require_location')
    FileUtils.rm loc
    FastRequire.save
    assert File.exist?(loc)
  end
end