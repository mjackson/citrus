require 'citrus'

module Citrus

  # A grammar for parsing expression grammars.
  class PEG < Grammar

    rule :rule do
      [name, ':', expr]
    end

    rule :name do
      /[a-zA-Z][a-zA-Z0-9_]*/
    end

    rule :expr do
      any(choice, sequence, primary)
    end

    rule :atomic do
      any(terminal, nonterminal, paren_expr)
    end

    rule :prefix do
      zero_or_one '~'
    end

    rule :suffix do
      any '*', '+', '?'
    end

  end
end
