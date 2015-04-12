[![Version     ](https://img.shields.io/gem/v/faster_require.svg?style=flat)](https://rubygems.org/gems/faster_require)

# Faster Require

A little utility to make load time faster, especially by making

```ruby
require 'xxx'
```

take much less time.  As in much less.  Well, on Windows at least it's faster.
It speeds up how long it takes things to load in Windows, like rails apps.

Well, mostly on Windows -- on linux it's a speedup of only 0.41 to 0.45s, or so. [[1]](#ref_1)

If you've ever wondered why ruby feels slow on doze...sometimes it's just the startup time.  This really helps.

Benchmarks:

Loading a (blank) rspec file:

  > ### 1.9.1
  > - without: 3.20s
  > - with: 0.34s (10x improvement)

  > ### 1.8.6
  > - without: 3.6s
  > - with: 1.25s


`rails app`, running a unit test:

 > ### 1.8.6
 > - without: 23s
 > - with: 14s

`rails app`, running `$ script/console "puts 333"`

  > ### 1.9.1
  > - without: 20s
  > -  with: 10s

  > ### 1.8.6
  > - without: 9s
  > - with: 6s

Running `rake -T` somewhere:

  > ### 1.9.1
  > - without: 3.75s
  > - with: 1.5s

  > ### 1.8.6
  > - without: 1.37s
  > - with:    1.25s

Note: in realit, what we should do is fix core so that it doesn't have such awful load time in Windows.  There may be some inefficiency in there.  For now, this is a work-around that helps.

Also it helps with SSD's even, on Windows, as it avoids some CPU used at require time, at least for 1.9.x

NB that installing newer versions of rubygems also seems to speedup start time (see below for how you can use them both, however, which is the best way).
In fact, 1.8.7 with newer rubygems and only very few requires seems pretty fast, even without faster_require.
Once you have any number of requires, though, you'll wantfaster_require.
Rails needs it, and 1.9 still needs it, though, even with a newer rubygems, so you'll get some benefit from this library always -- but don't take my word for it, profile it and find out for yourself.

## Usage

The naive we is to use it by installing the gem, then adding

```ruby
require 'rubygems'
require 'faster_require'
```

to the top of some (your initial) script.

However this doesn't speedup the loading of rubygems itself (_is XXX much speedup?_), so you can do this to get best performance:

```console
G:>gem which faster_require
C:/installs/Ruby187/lib/ruby/gems/1.8/gems/faster_require-0.7.4/lib/faster_require.rb
```

Now before doing require rubygems in your script, do this:

```ruby
require 'C:/installs/Ruby187/lib/ruby/gems/1.8/gems/faster_require-0.7.4/lib/faster_require.rb'
```

Then rubygems' load will be cached too. Which is faster.  Or see "installing globally" below.

## How to use in Rails

One way is to install the gem, then add a

```ruby
require 'rubygems'
require 'faster_require'
```

in your config/environment.rb, or (the better way is as follows):

1. Unpack it somewhere, like lib.
```console
$ cd my_rails_app/lib
$ gem unpack faster_require
```

2. Now add this line to your config/environment.rb:
```ruby
require File.dirname(__FILE__) + "/../lib/faster_require-0.7.0/lib/faster_require" # faster speeds all around...make sure to update it to whatever version number you fetched though.
```

3. Add that *before* this other (pre-existing) line:
```ruby
require File.join(File.dirname(__FILE__), 'boot')
```

Now faster_require will speedup loading rubygems and everything railsy. Happiness.  (NB that setting it this will also run in production mode code, so be careful here, though it does work for me fine for production).

Ping me if it's still too slow.

## Clearing the cache

If you use [Bundler](https://github.com/bundler/bundler) to change bundled gems, you'll want to run the command `$ faster_require --clear-cache` so that it will pick up any new load paths.  Also if you moves files around to new directories, you may want to do the same.
As you install any new gems, it should clear the paths automatically for you.

## How to use generally/globally

You can install it to be used "always" (well, for anything that loads rubygems, at least, which is most things, via something like the following):

```console
$ gem which rubygems
d:/Ruby192/lib/ruby/site_ruby/1.9.1/rubygems.rb

$ gem which faster_require
d:/Ruby192/lib/ruby/gems/1.9.1/gems/faster_require-0.6.0/lib/faster_require.rb
```

Now edit the rubygems.rb file, and add a require line to the top of it of the faster_require file, like this:

```ruby
require 'd:/Ruby192/lib/ruby/gems/1.9.1/gems/faster_require-0.6.0/lib/faster_require.rb'
```

at the top of rubygems.rb file

update the path to be your own, obviously. You'll also have to change that added line if
you ever install a newer version of faster_require gem, or if you update your version of rubygems,
as the rubygems.rb file will be wiped clean at that point.

This will cause everything to load faster.

## How to ignore PWD for faster_require

Faster_require also takes into consideration your Dir.pwd when you run it, for cacheing sake.
This means that if you run a ruby gem install script (like redcar's bin/redcar, for instance) and run it from different directories, it will always
be slow the first time you run it in each directory.
To make it be fast and basically disregard PWD, you can add global setting `$faster_require_ignore_pwd_for_cache = true`
and set it before requiring faster_require itself.

So now rubygems.rb at the top would look like
```ruby
$faster_require_ignore_pwd_for_cache = true
require 'd:/Ruby192/lib/ruby/gems/1.9.1/gems/faster_require-0.6.0/lib/faster_require.rb'
```

And now your gem scripts will run fast regardless of where you run them from.

## See also

[Spork](https://github.com/sporkrb/spork) can help speedup rails tests.  It "should" work well when used in conjunction with faster_require, as well.

Also [The Code Shop](http://thecodeshop.github.com) releases versions of Ruby that have an optimized require method, which might make this library obsolete. See:

* https://groups.google.com/group/thecodeshop

[1] <a name="ref_1"></a> http://itreallymatters.net/post/12897174267/speedup-ruby-1-9-3-on-windows#.T89_XtVYut0

Enjoy.
