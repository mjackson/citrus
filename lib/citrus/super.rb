module Citrus
  # A Super is a Proxy for a rule of the same name that was defined previously
  # in the grammar's inheritance chain. Thus, Super's work like Ruby's +super+,
  # only for rules in a grammar instead of methods in a module. The Citrus
  # notation is the word +super+ without any other punctuation, e.g.:
  #
  #     super
  #
  class Super < Proxy
    # Returns the Citrus notation of this rule as a string.
    def to_s
      'super'
    end

  private

    # Searches this proxy's included grammars for a rule with this proxy's
    # #rule_name. Raises an error if one cannot be found.
    def resolve!
      val = grammar.super_rule(rule_name)

      unless val
        raise RuntimeError,
          "No rule named \"#{rule_name}\" in hierarchy of grammar #{grammar.name}"
      end

      val
    end
  end
end
