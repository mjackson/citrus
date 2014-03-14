module Citrus
  # The current version of Citrus as [major, minor, patch].
  VERSION = [3, 0, 1]

  # Returns the current version of Citrus as a string.
  def self.version
    VERSION.join('.')
  end
end
