module Citrus
  # A standard error class that all Citrus errors extend.
  class Error < RuntimeError; end

  # Raised when a match cannot be found.
  class NoMatchError < Error; end

  # Raised when a parse fails.
  class ParseError < Error
    # The +input+ given here is an instance of Citrus::Input.
    def initialize(input)
      @offset = input.max_offset
      @line_offset = input.line_offset(offset)
      @line_number = input.line_number(offset)
      @line = input.line(offset)
      super "Failed to parse input on line #{line_number} at offset #{line_offset}\n#{detail}"
    end

    # The 0-based offset at which the error occurred in the input, i.e. the
    # maximum offset in the input that was successfully parsed before the error
    # occurred.
    attr_reader :offset

    # The 0-based offset at which the error occurred on the line on which it
    # occurred in the input.
    attr_reader :line_offset

    # The 1-based number of the line in the input where the error occurred.
    attr_reader :line_number

    # The text of the line in the input where the error occurred.
    attr_reader :line

    # Returns a string that, when printed, gives a visual representation of
    # exactly where the error occurred on its line in the input.
    def detail
      "#{line}\n#{' ' * line_offset}^"
    end
  end
end
