module Citrus
  # A Choice is a List where only one rule must match. The Citrus notation is
  # two or more expressions separated by a vertical bar, e.g.:
  #
  #     expr | expr
  #
  class Choice < Nonterminal
    # Returns an array of events for this rule on the given +input+.
    def exec(input, events=[])
      events << self

      index = events.size
      start = index - 1
      n = 0

      while n < rules.length && input.exec(rules[n], events).size == index
        n += 1
      end

      if index < events.size
        events << CLOSE
        events << events[-2]
      else
        events.slice!(start, events.size)
      end

      events
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      rules.map {|r| r.embed }.join(' | ')
    end
  end
end
