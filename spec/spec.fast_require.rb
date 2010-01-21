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
    @old_length = $LOADED_FEATURES.length
    $b = 0
  end

  def with_file(filename = 'test')
    FileUtils.touch filename + '.rb'
    yield
    FileUtils.rm filename + '.rb'
  end  
  
  it "should be able to go one deep" do
    Dir.chdir('files') do
      assert require('c')
      assert !(require 'c')
    end
    assert $LOADED_FEATURES.length == (@old_length + 1)
  end

  it "should be able to go two sub-requires deep, and not repeat" do
    Dir.chdir('files') do
      assert(require('a_requires_b'))
      assert !(require 'a_requires_b')
      assert !(require 'a_requires_b')
      $b.should == 1      
    end
  end
  
  it "should be faster" do
    Dir.chdir('files') do
      slow = Benchmark.realtime { assert system("#{OS.ruby_bin} slow.rb")}
      Benchmark.realtime { assert system("#{OS.ruby_bin} fast.rb")} # warmup
      fast = Benchmark.realtime { assert system("#{OS.ruby_bin} fast.rb")}
      pps 'fast', fast, 'slow', slow
      assert fast < slow
    end
  end
  
  it "should work with large complex gem" do
  	Dir.chdir('files') do
  		assert(system("#{OS.ruby_bin} large.rb"))
  		assert(system("#{OS.ruby_bin} large.rb"))
  		assert(system("#{OS.ruby_bin} large.rb")) # 3rd time, too
  	end
  end

  it "should cache when requires have already been done instead of calling require on them again"
  
  it "should not save if it hasn't changed"
  
  it "should require .so files still, and only once" do
    # ruby-prof gem
    2.times { require 'ruby_prof' } # .so
    RubyProf # should exist
    assert $LOADED_FEATURES.length == (@old_length + 1)
  end

  it "should add them to $LOADED_FEATURES" do
  	with_file('file2') {require 'file2'}
    assert ($LOADED_FEATURES.grep(/file2.rb/)).length > 0
    assert $LOADED_FEATURES.length == (@old_length + 1)
  end

  it "should work with and without rubygems, esp. in 1.8" do
    # run these tests in 1.8...hmm...
    # maybe with and
  end

  it "should save a file as a cache in a dir" do
    loc = File.expand_path('~/.ruby_fast_require_cache')
    FastRequire.clear_all!
    assert Dir[loc + '/*'].length == 0 # all clear
    FastRequire.save
    assert Dir[loc + '/*'].length > 0
  end
  
  it "should have different caches based on the file being run" do
   # that wouldn't help much at all for ruby-prof runs, but...we do what we can 
   loc = File.expand_path('~/.ruby_fast_require_cache')
   assert Dir[loc + '/*'].length == 0 # all clear
   Dir.chdir('files') do
   	  assert system("ruby -I../../lib d.rb")
   	  assert system("ruby -I../../lib e.rb")   	
   end
   assert Dir[loc + '/*'].length == 2    
   assert Dir[loc + '/*spec_files_d*'].length == 1 # use full path
  end
  
  it "should work with ascii files well" # most are binary, so...low prio
  it "should cache the converted file, if that speeds things up"
  
  it "should override the gem method if that's helpful"
end