# check for and avoid a double load...because we're afraid to load twice, since we override require et al

if(defined?($already_using_faster_require))
  p 'warning: faster_require double load--expected?' if $FAST_REQUIRE_DEBUG
  local_version = File.read(File.dirname(__FILE__) + "/../VERSION")
  raise "mismatched faster_require versions! #{local_version} != #{FastRequire::VERSION}" unless local_version == FastRequire::VERSION
else
  
$already_using_faster_require = true


require 'rbconfig' # maybe could cache this one's loc, too? probably not...

module FastRequire
  
  $FAST_REQUIRE_DEBUG ||= $DEBUG # can set this via $DEBUG, or on its own previously
  
  VERSION = File.read(File.dirname(__FILE__) + "/../VERSION")

  def self.sanitize filename
    filename.gsub(/[\/:]/, '_')
  end
  
  if RUBY_VERSION >= '1.9.0'
    # appears 1.9.x has inconsistent string hashes...so roll our own...
    def self.string_array_cruddy_hash strings
      # we only call this method once, so overflowing to a bignum is ok
      hash = 1;
      for string in strings
        hash = hash * 31
        string.each_byte{|b|
          hash += b
        }
      end
      hash # probably a Bignum (sigh)
    end
    
  else
    
    def self.string_array_cruddy_hash strings
      strings.hash
    end
    
  end

  def self.setup
    begin
     @@dir = File.expand_path('~/.ruby_faster_require_cache')
    rescue ArgumentError => e # couldn't find HOME environment or the like
     whoami = `whoami`.strip
     if File.directory?(home = "/home/#{whoami}")
      @@dir = home + '/.ruby_faster_require_cache'
     else
       raise e.to_s + " and couldnt infer it from whoami"
     end
    end

    unless File.directory?(@@dir)
      Dir.mkdir @@dir 
      raise 'unable to create user dir for faster_require ' + @@dir unless File.directory?(@@dir)
    end
    
    config = RbConfig::CONFIG
    
    # try to be a unique, but not too long, filename, for restrictions on filename length in doze
    ruby_bin_name = config['bindir'] + config['ruby_install_name'] # needed if you have two rubies, same box, same ruby description [version, patch number]
    parts = [File.basename($0), RUBY_PATCHLEVEL.to_s, RUBY_PLATFORM, RUBY_VERSION, RUBY_VERSION, File.expand_path(File.dirname($0)), ruby_bin_name]
    unless defined?($faster_require_ignore_pwd_for_cache)
      # add in Dir.pwd
      parts << File.basename(Dir.pwd)
      parts << Dir.pwd
    else
      p 'ignoring dirpwd for cached file location' if $FAST_REQUIRE_DEBUG
    end
    
    sanitized_parts = parts.map{|part| sanitize(part)}

    full_parts_hash = string_array_cruddy_hash(parts).to_s
    
    loc_name = (sanitized_parts.map{|part| part[0..5] + (part[-5..-1] || '')}).join('-') + '-' + full_parts_hash + '.marsh'
    
    @@loc = @@dir + '/' + loc_name
    
    if File.exist?(@@loc)
      FastRequire.load @@loc
    else
      @@require_locs = {}
    end
      
    @@already_loaded = {}
  
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
    # a special case--I hope...
  
    # also disallow re-loading $0
    @@require_locs[$0] = File.expand_path($0) # so when we run into $0 on a freak require, we will skip it...
    @@already_loaded[File.expand_path($0)] = true
    
  end
  
  def self.load filename
    cached_marshal_data = File.open(filename, 'rb') {|f| f.read}
    begin
      @@require_locs = Marshal.restore( cached_marshal_data )
    rescue ArgumentError
      @@require_locs= {}
    end
  end


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
  
  FastRequire.setup
  
  def self.already_loaded
    @@already_loaded
  end

  def self.require_locs
    @@require_locs
  end

  def self.dir
    @@dir
  end
  
  def self.loc
    @@loc
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

  # for testing use only, basically
  def self.clear_all!
    require 'fileutils'
    success = false
    if File.exist? @@dir
      FileUtils.rm_rf @@dir 
      success = true
    end
    @@require_locs.clear
    setup
    success
  end
  
  private
  def last_caller
   caller[-2]
  end
  
  IN_PROCESS = []
  ALL_IN_PROCESS = []
  @@count = 0
  
  public
  
  def require_cached lib
    lib = lib.to_s # might not be zactly 1.9 compat... to_path ??
    ALL_IN_PROCESS << [lib, @@count += 1]
    begin
      p 'doing require ' + lib + ' from ' + caller[-1] if $FAST_REQUIRE_DEBUG
      if known_loc = @@require_locs[lib]
        if @@already_loaded[known_loc]
          p 'already loaded ' + known_loc + ' ' + lib if $FAST_REQUIRE_DEBUG
          return false 
        end
        @@already_loaded[known_loc] = true
        if known_loc =~ /\.#{RbConfig::CONFIG['DLEXT']}$/
          puts 'doing original_non_cached_require on .so full path ' + known_loc if $FAST_REQUIRE_DEBUG
          original_non_cached_require known_loc # not much we can do there...too bad...well at least we pass it a full path though :P
        else
          unless $LOADED_FEATURES.include? known_loc
            if known_loc =~ /rubygems.rb$/
              puts 'requiring rubygems ' + lib if $FAST_REQUIRE_DEBUG
              original_non_cached_require(lib) # revert to normal require so rubygems doesn't freak out when it finds itself already in $LOADED_FEATURES with rubygems > 1.6 :P
            else
              IN_PROCESS << known_loc
              begin
                if $FAST_REQUIRE_DEBUG
                  puts 'doing cached loc eval on ' + lib + '=>' + known_loc + " with stack:" + IN_PROCESS.join(' ')
                end
                $LOADED_FEATURES << known_loc
                # fakely add the load path, too, so that autoload for the same file/path in gems will work <sigh> [rspec2]
                no_suffix_full_path = known_loc.gsub(/\.[^.]+$/, '')
                no_suffix_lib = lib.gsub(/\.[^.]+$/, '')
                libs_path = no_suffix_full_path.gsub(no_suffix_lib, '')
                libs_path = File.expand_path(libs_path) # strip off trailing '/'
                
                $: << libs_path unless $:.index(libs_path) # add in this ones real require path, so that neighboring autoloads will work
                known_locs_dir = File.dirname(known_loc)
                $: << known_locs_dir unless $:.index(known_locs_dir) # attempt to avoid the regin loading bug...yipes.
                
                # try some more autoload conivings...so that it won't attempt to autoload if it runs into it later...
                relative_full_path = known_loc.sub(libs_path, '')[1..-1]
                $LOADED_FEATURES << relative_full_path unless $LOADED_FEATURES.index(relative_full_path) # add in with .rb, too, for autoload 
                  
                # load(known_loc, false) # too slow
                
                # use eval: if this fails to load breaks re-save the offending file in binary mode, or file an issue on the faster_require tracker...
                contents = File.open(known_loc, 'rb') {|f| f.read} # read only costs 0.34/10.0 s...
                if contents =~ /require_relative/ # =~ is faster apparently faster than .include?
                  load(known_loc, false) # load is slow, but overcomes a ruby core bug: http://redmine.ruby-lang.org/issues/4487
                else
                  eval(contents, TOPLEVEL_BINDING, known_loc) # note the 'rb' here--this means it's reading .rb files as binary, which *typically* works...maybe unnecessary though?
                end
              ensure
                raise 'unexpected' unless IN_PROCESS.pop == known_loc
              end
              return true
            end
          else
            puts 'ignoring already loaded [circular require?] ' + known_loc + ' ' + lib if $FAST_REQUIRE_DEBUG
          end
        end
      else
        # we don't know the location--let Ruby's original require do the heavy lifting for us here
        old = $LOADED_FEATURES.dup
        p 'doing old non-known location require ' + lib if $FAST_REQUIRE_DEBUG
        if(original_non_cached_require(lib))
          # debugger might land here the first time you run a script and it doesn't have a require
          # cached yet...
          new = $LOADED_FEATURES - old
          found = new.last
  
          # incredibly, in 1.8.x, this doesn't always get set to a full path.
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
        
          # this is expected if it's for libraries required before faster_require was [like rbconfig]
          # raise 'actually expected' + lib if RUBY_VERSION >= '1.9.0'
          puts 'already loaded, apparently [require returned false], trying to discover how it was redundant... ' + lib if $FAST_REQUIRE_DEBUG
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
              puts 'unable to infer ' + lib + ' location' if $FAST_REQUIRE_DEBUG
              @@already_loaded[found] = true # so hacky...
            end
          end
          return false # XXXX test all these return values
        end
      end
    ensure
      raise 'huh' unless ALL_IN_PROCESS.pop[0] == lib
    end
  end

end

module Kernel

  # overwrite old require...
  include FastRequire
  if defined?(gem_original_require)
    class << self
      alias :original_remove_method :remove_method
      
      def remove_method method # I think this actually might be needed <sigh>
        if method.to_s == 'require'
          #p 'not removing old require, since that\'s ours now'
        else
          original_remove_method method
        end
      end
    
    end
    
    # similarly overwrite this one...I guess...1.9.x...rubygems uses this as its default...I think...
    alias :original_non_cached_require :gem_original_require
    alias :gem_original_require :require_cached
  else
    alias :original_non_cached_require :require
    alias :require :require_cached
  end
end

end