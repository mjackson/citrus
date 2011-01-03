module Citrus
  # The current version of Citrus as [major, minor, patch].
  VERSION = [2, 3, 2]

  # Returns the current version of Citrus as a string.
  def self.version
    VERSION.join('.')
  end
end
