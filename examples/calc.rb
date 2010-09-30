require 'citrus'

# A grammar for mathematical formulas that apply basic mathematical operations
# to all numbers, respecting operator precedence and grouping of expressions
# while ignoring whitespace.
#
# An identical grammar that is written using Citrus' own grammar syntax can be
# found in calc.citrus.
grammar :Calc do

  ## Hierarchy

  rule :term do
    any(:additive, :factor)
  end

  rule :additive do
    all(:factor, :additive_operator, :term) {
      additive_operator.value(factor.value, term.value)
    }
  end

  rule :factor do
    any(:multiplicative, :prefix)
  end

  rule :multiplicative do
    all(:prefix, :multiplicative_operator, :factor) {
      multiplicative_operator.value(prefix.value, factor.value)
    }
  end

  rule :prefix do
    any(:prefixed, :exponent)
  end

  rule :prefixed do
    all(:unary_operator, :prefix) {
      unary_operator.value(prefix.value)
    }
  end

  rule :exponent do
    any(:exponential, :primary)
  end

  rule :exponential do
    all(:primary, :exponential_operator, :prefix) {
      exponential_operator.value(primary.value, prefix.value)
    }
  end

  rule :primary do
    any(:group, :number)
  end

  rule :group do
    all(:lparen, :term, :rparen) { term.value }
  end

  ## Syntax

  rule :number do
    any(:float, :integer)
  end

  rule :float do
    all(:digits, '.', :digits, :space) { text.strip.to_f }
  end

  rule :integer do
    all(:digits, :space) { text.strip.to_i }
  end

  rule :digits do
    /[0-9]+(?:_[0-9]+)*/
  end

  rule :additive_operator do
    all(any('+', '-'), :space) { |a, b|
      a.send(text.strip, b)
    }
  end

  rule :multiplicative_operator do
    all(any('*', '/', '%'), :space) { |a, b|
      a.send(text.strip, b)
    }
  end

  rule :exponential_operator do
    all('**', :space) { |a, b|
      a ** b
    }
  end

  rule :unary_operator do
    all(any('~', '+', '-'), :space) { |n|
      op = text.strip
      # Unary + and - require an @.
      n.send(op == '~' ? op : '%s@' % op)
    }
  end

  rule :lparen, ['(', :space]
  rule :rparen, [')', :space]
  rule :space,  /[ \t\n\r]*/
end
