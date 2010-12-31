module Citrus
  # A Proxy is a Rule that is a placeholder for another rule. It stores the
  # name of some other rule in the grammar internally and resolves it to the
  # actual Rule object at runtime. This lazy evaluation permits us to create
  # Proxy objects for rules that we may not know the definition of yet.
  class Proxy < Rule
    def initialize(rule_name='<proxy>')
      super()
      self.rule_name = rule_name
    end

    # Sets the name of the rule this rule is proxy for.
    def rule_name=(rule_name)
      @rule_name = rule_name.to_sym
    end

    # The name of this proxy's rule.
    attr_reader :rule_name

    # Returns the underlying Rule for this proxy.
    def rule
      @rule ||= resolve!
    end

    # Returns an array of events for this rule on the given +input+.
    def exec(input, events=[])
      events << self

      index = events.size
      start = index - 1
      if input.exec(rule, events).size > index
        events << CLOSE
        events << events[-2]
      else
        events.slice!(start, events.size)
      end

      events
    end

  end
end
