module Citrus
  # An Alias is a Proxy for a rule in the same grammar. It is used in rule
  # definitions when a rule calls some other rule by name. The Citrus notation
  # is simply the name of another rule without any other punctuation, e.g.:
  #
  #     name
  #
  class Alias < Proxy
    # Returns the Citrus notation of this rule as a string.
    def to_s
      rule_name.to_s
    end

  private

    # Searches this proxy's grammar and any included grammars for a rule with
    # this proxy's #rule_name. Raises an error if one cannot be found.
    def resolve!
      val = grammar.rule(rule_name)

      unless val
        raise RuntimeError,
          "No rule named \"#{rule_name}\" in grammar #{grammar.name}"
      end

      val
    end
  end
end
