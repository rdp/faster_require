require 'faster_rubygems' if RUBY_VERSION < '1.9'
require 'sane'
assert !defined?(FastRequire) # so that we can loadup our unit tests sanely, using the old way LOL.
require 'sane'
require 'ruby-debug'
require 'spec/autorun'
require 'benchmark'

$: << File.dirname(__FILE__)

describe "faster requires" do

  def with_file(filename = 'test')
      FileUtils.touch filename + '.rb'
      yield
      FileUtils.rm filename + '.rb'
  end

  it "should be able to go one deep" do
    with_file do
      require 'test' # should not blow
    end
  end


  it "should be faster" do
    slow = Benchmark.realtime { system("#{OS.ruby_bin} slow.rb")}
    Benchmark.realtime { system("#{OS.ruby_bin} fast.rb")} # warmup
    fast = Benchmark.realtime { system("#{OS.ruby_bin} fast.rb")}
    pps 'fast', fast, 'slow', slow
    assert fast*2 < slow
  end
  
  it "should not save if it hasn't changed"
  it "should cache when requires have already been done instead of calling require on them again"
  it "should know which requires are currently active and avoid calling require on them again"

  it "should do two of the same requires" do
    with_file('test') do
      require 'test'
      require 'test'      
    end
  end

    require_relative '../lib/fast_require'
    before do # each
      ::FastRequire.clear!
    end

    it "should be able to go two deep" do
      
    end

    
    it "should require files still" do
      with_file('file1') { require 'file1'}
    end

    it "should require .so files still" do
      # ruby-prof gem
      2.times { require 'ruby_prof' } # .so
    end

    it "should add them to $LOADED_FEATURES" do
      with_file('file2') {require 'file2'}
      assert ($LOADED_FEATURES.grep(/file2.rb/)).length > 0
    end

    it "should work with and without rubygems, esp. in 1.8" do
      # run these tests in 1.8...hmm...
      # maybe with and
    end

    it "should have a faster require method--faster, my friend, faster!"

    it "should save a file" do
      FastRequire.clear!
      loc = File.expand_path('~/.ruby_fast_require_location')
      assert !File.exist?(loc)
      FastRequire.save
      assert File.exist?(loc)
    end

    it "should override the gem method"
end
