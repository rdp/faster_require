require 'rubygems' if RUBY_VERSION < '1.9'
require 'sane'
require_relative '../lib/fast_require' # before spec...
# unfortunately this doesn't help us since we clear before each test :P
require 'spec/autorun'
require 'benchmark'
#require 'ruby-debug'

#assert !defined?(FastRequire) # so that we can loadup our unit tests sanely, using the old way LOL.
require_relative '../lib/fast_require'

describe "faster requires" do

  before do
    FastRequire.clear_all!
  end

  def with_file(filename = 'test')
    FileUtils.touch filename + '.rb'
    yield
    FileUtils.rm filename + '.rb'
  end  
  
  it "should be able to go one deep" do
    Dir.chdir('files') do
      assert require 'c'
      assert !(require 'c')
    end
  end

  it "should be able to go two sub-requires deep, and not repeat" do
    Dir.chdir('files') do
      assert(require 'a_requires_b')
      assert !(require 'a_requires_b')
      assert !(require 'a_requires_b')
      $b.should == 1
    end
  end

  it "should be faster" do
    Dir.chdir('files') do
      slow = Benchmark.realtime { system("#{OS.ruby_bin} slow.rb")}
      Benchmark.realtime { system("#{OS.ruby_bin} fast.rb")} # warmup
      fast = Benchmark.realtime { system("#{OS.ruby_bin} fast.rb")}
      pps 'fast', fast, 'slow', slow
      assert fast*2 < slow
    end
  end

  it "should cache when requires have already been done instead of calling require on them again"
  
  it "should have different based on $0"
  it "should not save if it hasn't changed"
  
  it "should require .so files still, and only once" do
    # ruby-prof gem
    2.times { require 'ruby_prof' } # .so
    RubyProf # should exist
  end

  it "should add them to $LOADED_FEATURES" do
    with_file('file2') {require 'file2'}
    assert ($LOADED_FEATURES.grep(/file2.rb/)).length > 0
  end

  it "should work with and without rubygems, esp. in 1.8" do
    # run these tests in 1.8...hmm...
    # maybe with and
  end

  it "should save a file as a cache in a dir" do
    loc = File.expand_path('~/.fast_require_caches')
    FastRequire.clear_all!
    assert Dir[loc + '/*'].length == 0 # all clear
    FastRequire.save
    assert Dir[loc + '/*'].length > 0
  end
  
  it "should "
  
  it "should work with ascii files well" # most are binary, so...low prio
  it "should cache the converted file, if that speeds things up"
  
  it "should override the gem method if that's helpful"
end