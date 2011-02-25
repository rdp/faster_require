require 'rbconfig'

module FastRequire
  $FAST_REQUIRE_DEBUG ||= $DEBUG # can set it via $DEBUG, or by itself

  def self.setup
    @@dir = File.expand_path('~/.ruby_faster_require_cache')
    Dir.mkdir @@dir unless File.directory?(@@dir)
    
    parts = [File.basename($0), RUBY_VERSION, RUBY_PLATFORM, File.basename(Dir.pwd), Dir.pwd, File.dirname($0), File.expand_path(File.dirname($0))].map{|part| sanitize(part)}
    loc_name = (parts.map{|part| part[0..5]} + parts).join('-')[0..75] # try to be unique, but short...
    @@loc = @@dir + '/' + loc_name
  end

  def self.sanitize filename
    filename.gsub(/[\/:]/, '_')
  end

  FastRequire.setup

  def self.load filename
    @@require_locs = Marshal.restore( File.open(filename, 'rb') {|f| f.read})
  end

  if File.exist?(@@loc)
    FastRequire.load @@loc
  else
    @@require_locs = {}
  end

  @@already_loaded = {}

  # try to see where this file was loaded from, from $:
  # partial_name might be abc.rb, or might be abc
  # partial_name might be a full path, too
  def self.guess_discover partial_name, add_dot_rb = false

    # test for full path first
    # unfortunately it has to be a full separate test
    # for windoze sake, as drive letter could be different than slapping a '/' on the dir to test list...
    tests = [partial_name]

    if add_dot_rb
      tests << partial_name + '.rb'
      tests << partial_name + '.' + RbConfig::CONFIG['DLEXT']
    end

    tests.each{|b|
      # assume that .rb.rb is...valid...?
      if File.file?(b) && ((b[-3..-1] == '.rb') || (b[-3..-1] == '.' + RbConfig::CONFIG['DLEXT']))
        return File.expand_path(b)
      end
    }

    for dir in $:
      if File.file?(b = (dir + '/' + partial_name))
        # make sure we require a file that has the right suffix...
        if (b[-3..-1] == '.rb')  || (b[-3..-1] == '.' + RbConfig::CONFIG['DLEXT'])
          return File.expand_path(b)
        end

      end
    end

    if add_dot_rb && (partial_name[-3..-1] != '.rb') && (partial_name[-3..-1] != '.' + RbConfig::CONFIG['DLEXT'])
      guess_discover(partial_name + '.rb') || guess_discover(partial_name + '.')
    else
      nil
    end
  end

  $LOADED_FEATURES.each{|already_loaded|
    # in 1.8 they might be partial paths
    # in 1.9, they might be non collapsed paths
    # so we have to sanitize them here...
    # XXXX File.exist? is a bit too loose, here...
    if File.exist?(already_loaded)
      key = File.expand_path(already_loaded)
    else
      key = FastRequire.guess_discover(already_loaded) || already_loaded
    end
    @@already_loaded[key] = true
  }

  @@already_loaded[File.expand_path(__FILE__)] = true # this file itself isn't in loaded features, yet, but very soon will be..
  # special case--I hope...

  # disallow re-requiring $0
  @@require_locs[$0] = File.expand_path($0) # so when we run into it on a require, we will skip it...
  @@already_loaded[File.expand_path($0)] = true


  # XXXX within a very long depth to require fast_require,
  # require 'a' => 'b' => 'c' => 'd' & fast_require
  #             then
  #             => 'b.rb'
  # it works always

  def self.already_loaded
    @@already_loaded
  end

  def self.require_locs
    @@require_locs
  end

  def self.dir
    @@dir
  end

  at_exit {
    FastRequire.default_save
  }

  def self.default_save
    self.save @@loc
  end

  def self.save to_file
    File.open(to_file, 'wb'){|f| f.write Marshal.dump(@@require_locs)}
  end

  def self.clear_all!
    require 'fileutils'
    FileUtils.rm_rf @@dir if File.exist? @@dir
    @@require_locs.clear
    setup
  end
#   require 'ruby-debug'
  def require_cached lib
    lib = lib.to_s # might not be zactly 1.9 compat... to_path ??
   # p 'doing require ' + lib
    if known_loc = @@require_locs[lib]
      if @@already_loaded[known_loc]
        p 'already loaded ' + known_loc if $FAST_REQUIRE_DEBUG
        return false 
      end
      @@already_loaded[known_loc] = true
      if known_loc =~ /\.#{RbConfig::CONFIG['DLEXT']}$/
        puts 'doing original_non_cached_require on .so full path ' + known_loc if $FAST_REQUIRE_DEBUG
        original_non_cached_require known_loc # not much we can do there...too bad...well at least we pass it a full path though :P
      else
        unless $LOADED_FEATURES.include? known_loc
          if known_loc =~ /rubygems.rb$/
            puts 'requiring rubygems ' + known_loc if $FAST_REQUIRE_DEBUG
            original_non_cached_require(known_loc) # normal require so rubygems doesn't freak out when it finds itself already in $LOADED_FEATURES :P
          else
            if $FAST_REQUIRE_DEBUG
              puts 'doing cached loc eval on ' + lib + '=>' + known_loc 
            end
            $LOADED_FEATURES << known_loc
            # fakely add the load path, too, so that autoload for the same file will work <sigh> [rspec2]
            no_suffix_full_path = known_loc.gsub(/\.[^.]+$/, '')
            no_suffix_lib = lib.gsub(/\.[^.]+$/, '')
            libs_path = no_suffix_full_path.gsub(no_suffix_lib, '')
            libs_path = File.expand_path(libs_path) # strip off trailing '/'
            $: << libs_path unless $:.index(libs_path)
            # load(known_loc, false) # too slow
            eval(File.open(known_loc, 'rb') {|f| f.read}, TOPLEVEL_BINDING, known_loc) # note the rb here--this means it's reading .rb files as binary, which *typically* works...maybe unnecessary?
            # --if it breaks re-save the offending file in binary mode, or file an issue on the tracker...
            return true
          end
        else
          puts 'ignoring already loaded? ' + known_loc if $FAST_REQUIRE_DEBUG
        end
      end
    else
      # we don't know the location--let Ruby's original require do the heavy lifting for us here
      old = $LOADED_FEATURES.dup
      if(original_non_cached_require lib)
        # debugger might land here the first time you run a script and it doesn't have a require
        # cached yet...
        new = $LOADED_FEATURES - old
        found = new.last

        # incredibly, in 1.8.6, this doesn't always get set to a full path
        if RUBY_VERSION < '1.9'
          if !File.file?(found)
            # discover the full path.
            dir = $:.find{|path| File.file?(path + '/' + found)}
            return true unless dir # give up, case jruby socket.jar "mysterious"
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
        # this probably was something like
        # the first pass was require 'regdeferred'
        # now it's a different require 'regdeferred.rb'
        # which fails (or vice versa)
        # so figure out why
        # calc location, expand, map back
        where_found = FastRequire.guess_discover(lib, true)
        if where_found
          puts 'inferred lib loc:' + lib + '=>' + where_found if $FAST_REQUIRE_DEBUG
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
            # happens for enumerator XXXX
            puts 'unable to infer' + lib + ' in ' if $FAST_REQUIRE_DEBUG
            @@already_loaded[found] = true # hacky
          end
        end
        return false # XXXX test all these return values
      end
    end
  end

  def self.resetup!
    eval "module ::Kernel; alias :require :require_cached; end"
  end
end

module Kernel

  if(defined?(@already_using_faster_require))
    raise 'twice not allowed...'
    # *shouldn't* ever get here...unless I'm wrong...
  else
    @already_using_faster_require = true
    include FastRequire
    # overwrite old require...
    alias :original_non_cached_require :require
    FastRequire.resetup!
  end

end
