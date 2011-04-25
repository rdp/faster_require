require 'rubygems'

begin
  require 'psych' # sigh
rescue ::LoadError
end
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "faster_require"
    s.summary = "Speed library loading in Ruby"
    s.description = "A tool designed to speedup library loading (startup time) in Ruby by caching library locations"
    s.email = "rogerdpack@gmail.com"
    s.homepage = "http://github.com/rdp/faster_require"
    s.authors = ["Roger Pack", "faisal"]
    s.add_development_dependency 'redparse'
    s.add_development_dependency 'activesupport', '= 2.3.10'
    s.add_development_dependency 'actionpack', '= 2.3.10'
    s.add_development_dependency 'jeweler'
    s.add_development_dependency 'rspec', '>= 2'
    s.add_development_dependency 'sane'
    s.add_development_dependency 'facets'
    s.add_development_dependency 'ruby-prof'
    s.add_development_dependency 'rack-mount', '=0.6.14'
    s.add_development_dependency 'rack', '=1.2.2'
    
    # ALSO INSTALL THIS! ->
    # s.add_development_dependency 'ruby-debug' too... or ruby-debug19 pick your poison
  end