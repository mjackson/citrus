require 'citrus'

# A grammar for mathematical formulas that apply basic mathematical operations
# to all numbers, respecting operator precedence and grouping of expressions
# while ignoring whitespace.
#
# An identical grammar that is written using Citrus' own grammar syntax can be
# found in calc.citrus.
grammar :Calc do

  ## Hierarchical syntax

  rule :term do
    any(:additive, :factor) {
      first.value
    }
  end

  rule :additive do
    all(:factor, :additive_operator, :term) {
      additive_operator.value(factor.value, term.value)
    }
  end

  rule :factor do
    any(:multiplicative, :prefix) {
      first.value
    }
  end

  rule :multiplicative do
    all(:prefix, :multiplicative_operator, :factor) {
      multiplicative_operator.value(prefix.value, factor.value)
    }
  end

  rule :prefix do
    any(:prefixed, :exponent) {
      first.value
    }
  end

  rule :prefixed do
    all(:unary_operator, :prefix) {
      unary_operator.value(prefix.value)
    }
  end

  rule :exponent do
    any(:exponential, :primary) {
      first.value
    }
  end

  rule :exponential do
    all(:primary, :exponential_operator, :prefix) {
      exponential_operator.value(primary.value, prefix.value)
    }
  end

  rule :primary do
    any(:group, :number) {
      first.value
    }
  end

  rule :group do
    all(:lparen, :term, :rparen) {
      term.value
    }
  end

  ## Lexical syntax

  rule :number do
    any(:float, :integer) {
      first.value
    }
  end

  rule :float do
    all(:digits, '.', :digits, zero_or_more(:space)) {
      strip.to_f
    }
  end

  rule :integer do
    all(:digits, zero_or_more(:space)) {
      strip.to_i
    }
  end

  rule :digits do
    # Numbers may contain underscores in Ruby.
    /[0-9]+(?:_[0-9]+)*/
  end

  rule :additive_operator do
    all(any('+', '-'), zero_or_more(:space)) { |a, b|
      a.send(strip, b)
    }
  end

  rule :multiplicative_operator do
    all(any('*', '/', '%'), zero_or_more(:space)) { |a, b|
      a.send(strip, b)
    }
  end

  rule :exponential_operator do
    all('**', zero_or_more(:space)) { |a, b|
      a ** b
    }
  end

  rule :unary_operator do
    all(any('~', '+', '-'), zero_or_more(:space)) { |n|
      # Unary + and - require an @.
      n.send(strip == '~' ? strip : '%s@' % strip)
    }
  end

  rule :lparen, ['(', zero_or_more(:space)]
  rule :rparen, [')', zero_or_more(:space)]
  rule :space,  /[ \t\n\r]/
end
