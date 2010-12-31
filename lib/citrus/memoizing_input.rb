module Citrus
  # A MemoizingInput is an Input that caches segments of the event stream for
  # particular rules in a parse. This technique (also known as "Packrat"
  # parsing) guarantees parsers will operate in linear time but costs
  # significantly more in terms of time and memory required to perform a parse.
  # For more information, please read the paper on Packrat parsing at
  # http://pdos.csail.mit.edu/~baford/packrat/icfp02/.
  class MemoizingInput < Input
    def initialize(string)
      super(string)
      @cache = {}
      @cache_hits = 0
    end

    # A nested hash of rules to offsets and their respective matches.
    attr_reader :cache

    # The number of times the cache was hit.
    attr_reader :cache_hits

    def reset # :nodoc:
      @cache.clear
      @cache_hits = 0
      super
    end

    def exec(rule, events=[]) # :nodoc:
      c = @cache[rule] ||= {}

      e = if c[pos]
        @cache_hits += 1
        c[pos]
      else
        c[pos] = super(rule)
      end

      events.concat(e)
    end

    # Returns +true+ when using memoization to cache match results.
    def memoized?
      true
    end
  end
end
