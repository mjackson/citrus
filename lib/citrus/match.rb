module Citrus
  # The base class for all matches. Matches are organized into a tree where any
  # match may contain any number of other matches. This class provides several
  # convenient tree traversal methods that help when examining parse results.
  class Match
    def initialize(string, events=[])
      if events[-1] && string.length != events[-1]
        raise ArgumentError,
               "Invalid events for match length #{string.length}"
      end

      @string = string
      @events = events

      extend!
    end

    # The array of events that was passed to the constructor.
    attr_reader :events

    def application
      Rule::Application.from_events(@events.dup)
    end

    # An array of all names of this match. A name is added to a match object
    # for each rule that returns that object when matching. These names can then
    # be used to determine which rules were satisfied by a given match.
    def names
      @names ||= []
    end

    # The name of the lowest level rule that originally created this match.
    def name
      names.first
    end

    # Returns +true+ if this match has the given +name+.
    def has_name?(name)
      names.include?(name.to_sym)
    end

    # Returns an array of all Rule objects that extend this match.
    def extenders
      @extenders ||= begin
        extenders = []

        @events.each do |event|
          break if event == CLOSE
          rule = event
          extenders.unshift(rule)
          break unless rule.propagates_extensions?
        end

        extenders
      end
    end

    # Returns an array of Match objects that are immediate submatches of this
    # match in the order they appeared in the input.
    def matches
      @matches ||= begin
        matches = []
        stack = []
        offset = 0
        close = false
        index = 0

        while index < @events.size
          event = @events[index]
          if close
            start = stack.pop
            if stack.size == extenders.size
              matches << Match.new(@string.slice(offset, event),
                                   @events[start..index])
              offset += event
            end
            close = false
          elsif event == CLOSE
            close = true
          else
            stack << index
          end
          index += 1
        end

        matches
      end
    end

    # Returns an array of all sub-matches with the given +name+. If +deep+ is
    # +false+, returns only sub-matches that are immediate descendants of this
    # match.
    def find(name, deep=true)
      ms = matches.select {|m| m.has_name?(name) }
      matches.each {|m| ms.concat(m.find(name, deep)) } if deep
      ms
    end

    # A shortcut for retrieving the first immediate sub-match of this match. If
    # +name+ is given, attempts to retrieve the first immediate sub-match named
    # +name+.
    def first(name=nil)
      name ? find(name, false).first : matches.first
    end

    # The default value for a match is its string value. This method is
    # overridden in most cases to be more meaningful according to the desired
    # interpretation.
    alias value to_s

    def ==(other)
      case other
      when String
        @string == other
      when Match
        @string == other.to_s
      else
        super
      end
    end

    # Allows methods of this match's string to be called directly and provides
    # a convenient interface for retrieving the first match with a given name.
    def method_missing(sym, *args, &block)
      if @string.respond_to?(sym)
        @string.__send__(sym, *args, &block)
      else
        val = first(sym)

        unless val
          raise NoMatchError,
            "No match named \"#{sym}\" in #{self} (#{name})"
        end

        val
      end
    end

    def to_s
      @string
    end

    alias_method :to_str, :to_s

    def inspect
      @string.inspect
    end

    # Returns a string representation of this match that displays the entire
    # match tree for easy viewing in the console.
    def dump
      dump_lines.join("\n")
    end

    def dump_lines(indent='  ') # :nodoc:
      line = to_s.inspect
      line << " (" << names.join(',') << ")" unless names.empty?

      matches.inject([line]) do |lines, m|
        lines.concat(m.dump_lines(indent).map {|line| indent + line })
      end
    end

  private

    def extend! # :nodoc:
      extenders.each do |rule|
        rule.extend_match(self)
      end
    end
  end
end
