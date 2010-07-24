require 'citrus'

# A grammar for mathematical formulas that apply the basic four operations to
# non-negative numbers (integers and floats), respecting operator precedence and
# ignoring whitespace.
grammar :Calc do
  rule :term do
    any(:additive, :factor)
  end

  rule :additive do
    all(:factor, label(any(:plus, :minus), :operator), :term) {
      def value
        operator.apply(factor, term)
      end
    }
  end

  rule :factor do
    any(:multiplicative, :primary)
  end

  rule :multiplicative do
    all(:primary, label(any(:star, :slash), :operator), :factor) {
      def value
        operator.apply(primary, factor)
      end
    }
  end

  rule :primary do
    any(:term_paren, :number)
  end

  rule :term_paren do
    all(:lparen, :term, :rparen) {
      def value
        term.value
      end
    }
  end

  rule :number do
    any(:float, :integer)
  end

  rule :float do
    all(/[0-9]+/, '.', /[0-9]+/, :space) {
      def value
        text.strip.to_f
      end
    }
  end

  rule :integer do
    all(/[0-9]+/, :space) {
      def value
        text.strip.to_i
      end
    }
  end

  rule :plus do
    all('+', :space) {
      def apply(factor, term)
        factor.value + term.value
      end
    }
  end

  rule :minus do
    all('-', :space) {
      def apply(factor, term)
        factor.value - term.value
      end
    }
  end

  rule :star do
    all('*', :space) {
      def apply(primary, factor)
        primary.value * factor.value
      end
    }
  end

  rule :slash do
    all('/', :space) {
      def apply(primary, factor)
        primary.value / factor.value
      end
    }
  end

  rule :lparen, ['(', :space]
  rule :rparen, [')', :space]
  rule :space,  /[ \t\n\r]*/
end
