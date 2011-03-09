# can set this: $FAST_REQUIRE_DEBUG

if RUBY_VERSION < '1.9'
  require 'rubygems' # faster_rubygems, perhaps?
end

require 'sane'
require 'benchmark'

unless RUBY_PLATFORM =~ /java/
 require_relative '../lib/faster_require'
 cached = '.cached_spec_locs' + RUBY_VERSION
 # use it for our own local test specs
 begin
   require 'spec/autorun'
 rescue LoadError
  # rspec 2
  require 'rspec'
 end
 FastRequire.load cached if File.exist? cached
 FastRequire.save cached
else
  require 'spec/autorun'
  require_relative '../lib/faster_require'
end

describe "requires faster!" do

  before do
    FastRequire.clear_all!
    @old_length = $LOADED_FEATURES.length
    $b = 0
    @ruby = OS.ruby_bin + " "
  end

  def with_file(filename = 'test')
    FileUtils.touch filename + '.rb'
    yield
    FileUtils.rm filename + '.rb'
  end  
  
  it "should be able to do a single require" do
    Dir.chdir('files') do
      old = $LOADED_FEATURES.dup
      assert require('c')
      assert !(require 'c')
      new = $LOADED_FEATURES - old
      raise new.inspect if new.length != 1    
    end
  end

  it "should be able to go two sub-requires deep appropriately" do
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
  		assert(system("#{OS.ruby_bin} large.rb"))
  	end
  end
  
  it "could cache file contents, too, in theory...oh my"

  it "should not re-save the cache file if it hasn't changed [?]"
  
  it "should load .so files still, and only load them once" do
    # ruby-prof gem
    2.times { require 'ruby_prof.so'; RubyProf }
    assert $LOADED_FEATURES.length == (@old_length + 1)
  end

  it "should add requires to $LOADED_FEATURES" do
  	with_file('file2') {require 'file2'}
    assert ($LOADED_FEATURES.grep(/file2.rb/)).length > 0
    assert $LOADED_FEATURES.length == (@old_length + 1)
  end

  it "should save a file as a cache in a dir" do    
    assert Dir[FastRequire.dir + '/*'].length == 0 # all clear
    FastRequire.default_save
    assert Dir[FastRequire.dir + '/*'].length > 0
  end
  
  it "should have different caches based on the file being run, and Dir.pwd" do
   # that wouldn't help much at all for ruby-prof runs, but...we do what we can 
   assert Dir[FastRequire.dir + '/*'].length == 0 # all clear
   Dir.chdir('files') do
   	  assert system("ruby -I../../lib d.rb")
   	  assert system("ruby -I../../lib e.rb")
   	  assert system("ruby -C.. -I../lib files/e.rb")
   end
 # require 'ruby-debug'
#  debugger
   assert Dir[FastRequire.dir + '/*'].length == 3    
   assert Dir[FastRequire.dir + '/*d.rb*'].length == 1 # use full path
   assert Dir[FastRequire.dir + '/*e.rb*'].length == 2 # different Dir.pwd's
  end
    
  context "should work with ascii files well" do # most are binary, so...low prio
    it "could cache the converted file, if that speeds things up"
  end
  
  private
  
  def ruby filename
    command = @ruby + " " + filename
    3.times { raise command unless system(command) }    
  end
  
  it "should override rubygems' require if rubygems is loaded after the fact...maybe by hooking to Gem::const_defined or something" do
    ruby "files/gem_after.rb"
  end
  
  it "should override rubygems' require if rubygems is loaded before the fact" do
    ruby "files/gem_before.rb"    
  end  
  
 ['gem_after.rb', 'load_various_gems.rb', 'load_various_gems2.rb', 'load_various_gems3.rb', 'fast.rb'].each{|filename| 
    it "should not double load gems #{filename}" do
      3.times {
        a = `#{@ruby} -v files/#{filename} 2>&1`
        a.should_not match('already initialized')
        a.should_not match('from ') # an error backtrace...
        a.should_not match(' warning: method redefined')
        a.length.should be > 0
      }
    end
  }

  it "should throw if you require itself twice" do
    Dir.chdir('files') do
      assert !system(@ruby + 'attempt_double_load.rb')
    end
  end
  
  it "require 'abc' should not attempt to load file called exactly abc" do
    Dir.chdir('files') do
      ruby 'require_non_dot_rb_fails.rb'
    end
  end
  
  it "should handle full path requires" do
    Dir.chdir('files') do
     ruby 'require_full_path.rb' 
    end
  end
  
  it "should handle Pathname requires, too" do
    require 'pathname'
    require Pathname.new('pathname')
  end  
  
  it "should work well with rubygems for gem libs (installed), themselves"
  
  it "should disallow a file requiring itself" do
    ruby 'files/requires_itself.rb'
  end
  
  it "should put modules in the right place" do
    Dir.chdir('files') do
      ruby 'should_put_modules_in_right_place.rb'
    end
  end

  it "should do this type loading too" do
    Dir.chdir('files') do
      ruby 'fast2.rb'
    end
  end
  
  it "should be able to infer .so files like socket.so" #do
#    ruby "files/load_socket.rb" # LODO
#  end


end