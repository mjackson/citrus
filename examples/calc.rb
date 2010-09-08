require 'citrus'

# A grammar for mathematical formulas that apply the basic four operations to
# non-negative numbers (integers and floats), respecting operator precedence and
# ignoring whitespace.
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
      def value
        additive_operator.apply(factor.value, term.value)
      end
    }
  end

  rule :factor do
    any(:multiplicative, :exponent)
  end

  rule :multiplicative do
    all(:exponent, :multiplicative_operator, :factor) {
      def value
        multiplicative_operator.apply(primary.value, factor.value)
      end
    }
  end

  rule :exponent do
    any(:exponential, :primary)
  end

  rule :exponential do
    all(:primary, :exponential_operator, :exponent) {
      def value
        exponential_operator.apply(primary.value, exponent.value)
      end
    }
  end

  rule :primary do
    any(:group, :number)
  end

  rule :group do
    all(:lparen, :term, :rparen) {
      def value
        term.value
      end
    }
  end

  ## Syntax

  rule :number do
    any(:float, :integer)
  end

  rule :float do
    all(:digits, '.', :digits, :space) {
      def value
        text.strip.to_f
      end
    }
  end

  rule :integer do
    all(:digits, :space) {
      def value
        text.strip.to_i
      end
    }
  end

  rule :digits do
    /[0-9]+(?:_[0-9]+)*/
  end

  rule :additive_operator do
    all(any('+', '-'), :space) {
      def apply(factor, term)
        factor.send(text.strip, term)
      end
    }
  end

  rule :multiplicative_operator do
    all(any('*', '/', '%'), :space) {
      def apply(primary, factor)
        primary.send(text.strip, factor)
      end
    }
  end

  rule :exponential_operator do
    all('**', :space) {
      def apply(primary, exponent)
        primary ** exponent
      end
    }
  end

  rule :lparen, ['(', :space]
  rule :rparen, [')', :space]
  rule :space,  /[ \t\n\r]*/
end
