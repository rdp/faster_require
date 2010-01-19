module FastRequire

  def self.setup
    @@dir = File.expand_path('~/.fast_require_caches')
    Dir.mkdir @@dir unless File.directory?(@@dir)    
    @@loc = @@dir + '/' + RUBY_VERSION + '-' + RUBY_PLATFORM # hope this is specific enough...
  end
  
  FastRequire.setup
  
  if File.exist?(@@loc)
    @@require_locs = Marshal.restore( File.open(@@loc, 'rb') {|f| f.read})    
  else
    @@require_locs = {}
  end
  @@already_loaded = {}
  $LOADED_FEATURES.each{|loaded| @@already_loaded[loaded] = true}

  at_exit {
    FastRequire.save
  }

  def self.save
    File.open(@@loc, 'wb'){|f| f.write Marshal.dump(@@require_locs)}
  end

  def self.clear_all!
    require 'fileutils'
    FileUtils.rm_rf @@dir if File.exist? @@dir
    @@require_locs.clear
    setup
  end

  def require_cached lib
    if a = @@require_locs[lib]
      return if @@already_loaded[a]
      @@already_loaded[a] = true
      if a =~ /.so$/
        puts 'doing original require on full path' if $DEBUG
        original_non_cached_require a # not much we can do there...too bad...
      else
        puts 'doing eval on ' + lib + '=>' + a if $DEBUG
        eval(File.open(a, 'rb') {|f| f.read}, TOPLEVEL_BINDING, a) # note the b here--this means it's reading .rb files as binary, which *typically* works--if it breaks re-save the offending file in binary mode...
        $LOADED_FEATURES << a        
      end      
    else
      old = $LOADED_FEATURES.dup
      if(original_non_cached_require lib)
        new = $LOADED_FEATURES - old
        @@require_locs[lib] = new.last
        puts 'found new loc:' + lib + '=>' + @@require_locs[lib] if $DEBUG
        @@already_loaded[@@require_locs[lib]] = true
      end# how could this fail, though...
    end
    
  end
end

module Kernel
	
  if(defined?(@already_using_fast_require))
    raise 'cant require it twice...'
  else
    @already_using_fast_require = true
  end
  
  include FastRequire
  # overwrite require...
  alias :original_non_cached_require :require
  alias :require :require_cached 
end