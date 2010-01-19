if defined?($b) && $b > 0   
  raise 'cannot require b twice'
end
$b = 1