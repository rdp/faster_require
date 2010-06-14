Gem.post_install { |gem_installer_instance|
  require 'faster_require'
  FastRequire.clear_all!
  puts 'cleared faster_require caches due to new gem install...'
}