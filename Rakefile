  require 'rubygems' if RUBY_VERSION < "1.9'"
  
begin
  require 'psych' # sigh
rescue ::LoadError
end
  
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "faster_require"
    s.summary = "Speed library loading in Ruby"
    s.description = "A tool designed to speedup library loading in Ruby by caching library locations"
    s.email = "rogerdpack@gmail.com"
    s.homepage = "http://github.com/rdp/faster_require"
    s.authors = ["Roger Pack"]
    s.add_development_dependency 'redparse'
    s.add_development_dependency 'active_support', '= 2.3.10'
#    s.add_development_dependency 'ruby-debug' too... or ruby-debug19 pick your poison
    s.add_development_dependency 'jeweler'
    s.add_development_dependency 'rspec', '>= 2'
    s.add_development_dependency 'sane'
    s.add_development_dependency 'ruby-prof'
    # s.add_dependency
  end