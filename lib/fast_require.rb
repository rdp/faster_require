module FastRequire

  def self.setup
    @@dir = File.expand_path('~/.ruby_fast_require_cache')

    Dir.mkdir @@dir unless File.directory?(@@dir)
    @@loc = @@dir + '/' + RUBY_VERSION + '-' + RUBY_PLATFORM + '-' + sanitize(File.expand_path($0).gsub(/[\/:]/, '_')) + sanitize(Dir.pwd)
  end
  
  def self.sanitize filename
    filename.gsub(/[\/:]/, '_')
  end

  FastRequire.setup

  if File.exist?(@@loc)
    @@require_locs = Marshal.restore( File.open(@@loc, 'rb') {|f| f.read})
  else
    @@require_locs = {}
  end
  @@already_loaded = {}
  $LOADED_FEATURES.each{|loaded| @@already_loaded[loaded] = true}

  def self.already_loaded
    @@already_loaded
  end

  def self.dir
    @@dir
  end

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
    puts 'got require ' + lib if $DEBUG
    #debugger if lib =~ /regdeferred/
    if a = @@require_locs[lib]
      return if @@already_loaded[a]
      @@already_loaded[a] = true
      if a =~ /.so$/
        puts 'doing original_non_cached_require on full path ' + a if $DEBUG
        original_non_cached_require a # not much we can do there...too bad...
      else
        puts 'doing eval on ' + lib + '=>' + a if $DEBUG
        eval(File.open(a, 'rb') {|f| f.read}, TOPLEVEL_BINDING, a) # note the b here--this means it's reading .rb files as binary, which *typically* works--if it breaks re-save the offending file in binary mode...
        $LOADED_FEATURES << a
      end
    else
      # handle a circular require of regdeferred => something -> loop { regdeferred.rb }
      return if @@already_loaded[lib]

      old = $LOADED_FEATURES.dup
      if(original_non_cached_require lib )
        new = $LOADED_FEATURES - old

        found = new.last

        # incredibly, in 1.8.6, this doesn't actually have to be a full path
        if RUBY_VERSION < '1.9'
          # so discover the full path.
          dir = $:.find{|path| File.exist?(path + '/' + found)}
          found = dir + '/' + found
        end
        puts 'found new loc:' + lib + '=>' + found if $DEBUG
        @@require_locs[lib] = found
        @@already_loaded[found] = true
      else
=begin this is still buggy...
      	#@@already_loaded[lib] = true
        # this probably failed [1.8.6 only?] like
        # the first pass was require 'regdeferred'
        # now it's require 'regdeferred.rb'
        # which fails (or vice versa)
        # so figure out why
        # calc location, expand, map back
        glob = '{' + $:.join(',') + '}'
        if lib =~ /(.rb|.so)$/
        	all = glob + "/#{lib}"
        else
          all = glob + "/#{lib}.{rb,so}"
        end
        all2 = Dir[all]
        where_found = all2[0]
        puts 'freaky found new loc:' + lib + '=>' + where_found if $DEBUG
        @@require_locs[lib] = where_found
        @@already_loaded[found] = true
=end
      end
    end

  end
  
  
  def self.resetup!
    eval "module ::Kernel; alias :require :require_cached; end"
  end
end

module Kernel

  if(defined?(@already_using_fast_require))
    raise 'cant yet require it twice...'
  else
    @already_using_fast_require = true
  end

  include FastRequire
  # overwrite old require...
  alias :original_non_cached_require :require
  FastRequire.resetup!

end

if(!defined?(Gem::Specification))
  # don't let Gem ruin my fun, though it still does partially
  module Gem
    class << self
      alias :original_const_missing :const_missing
      def const_missing *args
        puts 'got const missing', args
        FastRequire.resetup!
        original_const_missing *args
      end
    end
  end
end
