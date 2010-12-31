module Citrus
  # An Input is a scanner that is responsible for executing rules at different
  # positions in the input string and persisting event streams.
  class Input < StringScanner
    def initialize(string)
      super(string)
      @max_offset = 0
    end

    # The maximum offset in the input that was successfully parsed.
    attr_reader :max_offset

    def reset # :nodoc:
      @max_offset = 0
      super
    end

    # Returns the length of this input.
    def length
      string.length
    end

    # Returns an array containing the lines of text in the input.
    def lines
      if string.respond_to?(:lines)
        string.lines.to_a
      else
        string.to_a
      end
    end

    # Iterates over the lines of text in the input using the given +block+.
    def each_line(&block)
      string.each_line(&block)
    end

    # Returns the 0-based offset of the given +pos+ in the input on the line
    # on which it is found. +pos+ defaults to the current pointer position.
    def line_offset(pos=pos)
      p = 0
      string.each_line do |line|
        len = line.length
        return (pos - p) if p + len >= pos
        p += len
      end
      0
    end

    # Returns the 0-based number of the line that contains the character at the
    # given +pos+. +pos+ defaults to the current pointer position.
    def line_index(pos=pos)
      p = n = 0
      string.each_line do |line|
        p += line.length
        return n if p >= pos
        n += 1
      end
      0
    end

    # Returns the 1-based number of the line that contains the character at the
    # given +pos+. +pos+ defaults to the current pointer position.
    def line_number(pos=pos)
      line_index(pos) + 1
    end

    alias_method :lineno, :line_number

    # Returns the text of the line that contains the character at the given
    # +pos+. +pos+ defaults to the current pointer position.
    def line(pos=pos)
      lines[line_index(pos)]
    end

    # Returns an array of events for the given +rule+ at the current pointer
    # position. Objects in this array may be one of three types: a Rule,
    # Citrus::CLOSE, or a length (integer).
    def exec(rule, events=[])
      start = pos
      index = events.size

      rule.exec(self, events)

      if index < events.size
        self.pos = start + events[-1]
        @max_offset = pos if pos > @max_offset
      else
        self.pos = start
      end

      events
    end

    # Returns the length of a match for the given +rule+ at the current pointer
    # position, +nil+ if none can be made.
    def test(rule)
      rule.exec(self)[-1]
    end

    # Returns +true+ when using memoization to cache match results.
    def memoized?
      false
    end
  end
end