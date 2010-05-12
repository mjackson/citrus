require 'citrus'

module Citrus
  module GrammarMethods
    # Permits creation of aliases within rule definitions in Ruby grammars using
    # the bare name of another rule instead of a Symbol, e.g.:
    #
    #     rule :value do
    #       any(:alpha, :num)
    #     end
    #
    # can now be written as
    #
    #     rule value do
    #       any(alpha, num)
    #     end
    #
    # The only caveat is that since this hack uses +method_missing+ you must
    # still use symbols for rules that have the same name as any of the methods
    # in GrammarMethods (root, rule, rules, etc.)
    def method_missing(sym, *args)
      sym
    end
  end
end
