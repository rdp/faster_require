module FastRequire

  @@loc = File.expand_path('~/.ruby_fast_require_location')
  if File.exist? (@@loc)
    @@require_locs = Marshal.restore( File.open(@@loc, 'rb') {|f| f.read})
  else
    @@require_locs = {}
  end

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
      begin
        puts 'doing eval', a
        if a =~ /.so$/
          original_non_cached_require a # not much we can do there...hmm...
        else
          eval File.open(a, 'rb') {|f| f.read} # binread
          $LOADED_FEATURES << a
        end        
      rescue => e
        debugger
        3
        raise e
      end
    else
      old = $LOADED_FEATURES.dup
      puts lib.to_s      
      if(original_non_cached_require lib)
        new = $LOADED_FEATURES - old
        @@require_locs[lib] = new.last      
      end# how could this fail, though?
    end
    
  end
end

module Kernel
  if(defined?(@already_using_fast_require))
    raise 'cant require it twice'
  else
    @already_using_fast_require = true
  end
  alias :original_non_cached_require :require
  include FastRequire   # overwrite require...
  alias :require :require_cached
end
