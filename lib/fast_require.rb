require 'sane' # TODO take out
require 'ruby-debug'


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
  
  def require lib
    puts lib
    if a = @@require_locs[lib]
      puts 'miss'
      eval File.open(a, 'rb') {|f| f.read} # binread
    else
      puts 'hit'
      
      old = $LOADED_FEATURES.dup
      original_require lib
      new = $LOADED_FEATURES - old
      @@required[lib] = new.last
    end
  end
end

module Kernel
  alias :original_require :require
  extend FastRequire   # overwrite require...
end

