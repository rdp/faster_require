module Kernel
  alias :original_require :require
  def require lib
    original_require lib
  end
end