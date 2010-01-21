Gem.post_install { |gem_installer_instance|
  require 'fast_require'
  FastRequire.clear_all!
  puts 'cleared fast_require caches due to new gem install...'
}