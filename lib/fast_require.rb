module FastRequire
  $FAST_REQUIRE_DEBUG ||= false
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


  def self.guess_discover partial_name, add_dot_rb = false
    for dir in $:
      if File.file?(b = (dir + '/' + partial_name))
        return File.expand_path(b)
      end
    end
    
    if add_dot_rb
      return guess_discover(partial_name + '.rb') || guess_discover(partial_name + '.so')
    else
      nil
    end
  end

  $LOADED_FEATURES.each{|loaded|
    if RUBY_VERSION < '1.9'
      @@already_loaded[FastRequire.guess_discover(loaded) || loaded] = true
    else
      @@already_loaded[loaded] = true
    end
  }


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
    if known_loc = @@require_locs[lib]
      return false if @@already_loaded[known_loc]
      @@already_loaded[known_loc] = true
      if known_loc =~ /.so$/
        puts 'doing original_non_cached_require on .so full path ' + known_loc if $FAST_REQUIRE_DEBUG
        original_non_cached_require known_loc # not much we can do there...too bad...
      else
        puts 'doing eval on ' + lib + '=>' + known_loc if $FAST_REQUIRE_DEBUG
        $LOADED_FEATURES << known_loc # *must*
        eval(File.open(known_loc, 'rb') {|f| f.read}, TOPLEVEL_BINDING, known_loc) # note the b here--this means it's reading .rb files as binary, which *typically* works--if it breaks re-save the offending file in binary mode...
        return true
      end
    else
      # handle a circular require of regdeferred => something -> loop { regdeferred.rb }
      old = $LOADED_FEATURES.dup
      if(original_non_cached_require lib)
        new = $LOADED_FEATURES - old
        found = new.last

        # incredibly, in 1.8.6, this doesn't always end up as set to a full path
        if RUBY_VERSION < '1.9'
          if !File.file?(found)
            # so discover the full path.
            dir = $:.find{|path| File.file?(path + '/' + found)}
            puts "got dir as " + dir.to_s + " for " + found if $FAST_REQUIRE_DEBUG
            found = dir + '/' + found
          end
          found = File.expand_path(found);
        end
        puts 'found new loc:' + lib + '=>' + found if $FAST_REQUIRE_DEBUG
        @@require_locs[lib] = found
        @@already_loaded[found] = true
        return true
      else
        puts 'already loaded, apparently' + lib if $FAST_REQUIRE_DEBUG
        # this probably failed like
        # the first pass was require 'regdeferred'
        # now it's require 'regdeferred.rb'
        # which fails (or vice versa)
        # so figure out why
        # calc location, expand, map back
        where_found = FastRequire.guess_discover(lib, true)
        if where_found
          puts 'inferred ghost loc:' + lib + '=>' + where_found if $FAST_REQUIRE_DEBUG
          @@require_locs[lib] = where_found
          # unfortunately if it's our first pass
          # and we are in the middle of a "real" require
          # that is circular
          # then $LOADED_FEATURES or (AFAIK) nothing will have been set
          # for us to be able to assert that
          # so...I think we'll end up
          # just fudging for a bit
          #	raise 'not found' unless @@already_loaded[where_found] # should have already been set...I think...
        else
          if $FAST_REQUIRE_DEBUG
            puts 'unable to infer' + lib
            puts $:
          end
        end
        return false # XXXX check these return values
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
  
  def method_added *args
    puts 'kernel method added', *args
  end

end
