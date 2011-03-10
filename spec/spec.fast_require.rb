# could also  set this here if desired: $FAST_REQUIRE_DEBUG = true

require 'rubygems' # faster_rubygems, perhaps?
require 'sane'
require 'benchmark'

raise 'double faster_require' if defined?($already_using_faster_require) # disallowed, since who knows what version the gem one is...

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
  
  it "should load rubygems for speed look" do
    slow = Benchmark.realtime { assert system("#{OS.ruby_bin} files/time_just_loading_rubygems.rb")}
    fast = Benchmark.realtime { assert system("#{OS.ruby_bin} files/time_just_loading_rubygems.rb")}
    pps 'just loading rubygems [obviously depends on number of gems installed] at all: fast', fast, 'slow', slow
  end
  
  it "should work with large complex gem" do
  	Dir.chdir('files') do
  		3.times { assert(system("#{OS.ruby_bin} large.rb")) }
  	end
  end
  
  it "could cache the file contents, even, too, in theory...oh my"

  it "should not re-save the cache file if it hasn't changed [?]"
  
  it "should load .so files still, and only load them once" do
    # ruby-prof gem
    3.times { require 'ruby_prof.so'; RubyProf }
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
   assert Dir[FastRequire.dir + '/*'].length == 3    
   assert Dir[FastRequire.dir + '/*d.rb*'].length == 1 # use full path
   assert Dir[FastRequire.dir + '/*e.rb*'].length == 2 # different Dir.pwd's
  end
    
  it "should work with encoded files too" # most are binary, so...low prio

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
  
 ['require_facets.rb', 'gem_after.rb', 'load_various_gems.rb', 'load_various_gems2.rb', 'active_support_no_double_load.rb', 'fast.rb'].each{|filename| 
    it "should not double load gems #{filename}" do
      3.times {
        a = `#{@ruby} -v files/#{filename} 2>&1`
        a.should_not match('already initialized')
        a.should_not match('from ') # an error backtrace...
        a.should_not match('discarding old deep_const_get')
        a.length.should be > 0
      }
    end
  }

  it "should be ok if you require itself twice" do
    Dir.chdir('files') do
      3.times { assert system(@ruby + 'attempt_double_load.rb') }
      assert `#{@ruby + 'attempt_double_load.rb'}` =~ /double load expected/
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
#    ruby "files/socket_load.rb" # LODO reproduce failure
#  end


end