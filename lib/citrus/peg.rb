require 'citrus'

module Citrus

  # A grammar for parsing expression grammars.
  class PEG < Grammar

    ignore /[ \t\s\n]+/

    root :grammar

    rule :grammar       { any root, rule, ignore }
    rule :root          { ['root', name] }
    rule :rule          { ['rule', name, ':', expr] }
    rule :ignore        { ['ignore', regexp] }
    rule :expr          { any sequence, choice, terminal }
    rule :paren_expr    { ['(', expr, ')'] }
    rule :terminal      { any string, regexp }

    rule :name do
      /^[a-zA-Z][a-zA-Z0-9_]*/
    end

    rule :num do
      /^[0-9]+/
    end

    rule :string do
      /^(["']).*?\1/
    end

    rule :regexp do
      /^\//
    end

    rule :suffix do
      any [zero_or_one(num), '*', zero_or_one(num)], '+', '?'
    end

  end
end
