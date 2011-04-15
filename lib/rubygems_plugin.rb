Gem.post_install { |gem_installer_instance|
  require 'faster_require'
  if FastRequire.clear_all!
    puts 'cleared faster_require caches due to new gem install...'
  else
    puts '(faster_require had no cache to clear/reset)'
  end
}