module Citrus
  # A StringTerminal is a Terminal that may be instantiated from a String
  # object. The Citrus notation is any sequence of characters enclosed in either
  # single or double quotes, e.g.:
  #
  #     'expr'
  #     "expr"
  #
  # This notation works the same as it does in Ruby; i.e. strings in double
  # quotes may contain escape sequences while strings in single quotes may not.
  # In order to specify that a string should ignore case when matching, enclose
  # it in backticks instead of single or double quotes, e.g.:
  #
  #     `expr`
  #
  # Besides case sensitivity, case-insensitive strings have the same semantics
  # as double-quoted strings.
  class StringTerminal < Terminal
    # The +flags+ will be passed directly to Regexp#new.
    def initialize(rule='', flags=0)
      super(Regexp.new(Regexp.escape(rule), flags))
      @string = rule
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      if case_sensitive?
        @string.inspect
      else
        @string.inspect.gsub(/^"|"$/, '`')
      end
    end
  end
end
