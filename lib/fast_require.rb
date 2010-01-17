module FastRequire

  @@loc = File.expand_path('~/.ruby_fast_require_location')
  if File.exist? (@@loc)
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

  def self.clear!
    require 'fileutils'
    FileUtils.rm @@loc if File.exist? @@loc
    @@require_locs.clear
  end

  def require_cached lib
    if a = @@require_locs[lib]
      return if @@already_loaded[a]
      @@already_loaded[a] = true
      if a =~ /.so$/
        puts 'doing original require on full path'
        original_non_cached_require a # not much we can do there...too bad...
      else
        pss 'doing eval on ' + lib + '=>' + a
        eval(File.open(a, 'rb') {|f| f.read}, TOPLEVEL_BINDING, a)
        $LOADED_FEATURES << a        
      end      
    else
      old = $LOADED_FEATURES.dup
      pps 'searching', lib.to_s      
      if(original_non_cached_require lib)
        new = $LOADED_FEATURES - old
        @@require_locs[lib] = new.last
        pps 'found it:' + lib + '=>' + @@require_locs[lib]
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
  alias :original_non_cached_require :require
  include FastRequire   # overwrite require...
  alias :require :require_cached
end

