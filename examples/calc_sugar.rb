require 'citrus/sugar'

# A grammar for mathematical formulas that apply the basic four operations to
# non-negative numbers (integers and floats), respecting operator precedence and
# ignoring whitespace.
Calc = Citrus::Grammar.new {
  module FirstValue
    def value
      first.value
    end
  end

  rule term do
    ext(any(additive, factor), FirstValue)
  end

  rule additive do
    all(factor, label(additive_op, operator), term) {
      def value
        operator.apply(factor.value, term.value)
      end
    }
  end

  rule factor do
    ext(any(multiplicative, primary), FirstValue)
  end

  rule multiplicative do
    all(primary, label(multiplicative_op, operator), factor) {
      def value
        operator.apply(primary.value, factor.value)
      end
    }
  end

  rule primary do
    ext(any(term_paren, number), FirstValue)
  end

  rule term_paren do
    all(lparen, term, rparen) {
      def value
        term.value
      end
    }
  end

  rule additive_op do
    any(plus, minus) {
      def apply(factor, term)
        text.strip == '+' ? factor + term : factor - term
      end
    }
  end

  rule multiplicative_op do
    any(star, slash) {
      def apply(primary, factor)
        text.strip == '*' ? primary * factor : primary / factor
      end
    }
  end

  rule number do
    ext(any(float, integer), FirstValue)
  end

  rule float do
    all(/[0-9]+/, '.', /[0-9]+/, space) {
      def value
        text.strip.to_f
      end
    }
  end

  rule integer do
    all(/[0-9]+/, space) {
      def value
        text.strip.to_i
      end
    }
  end

  rule lparen, ['(', space]
  rule rparen, [')', space]
  rule plus,   ['+', space]
  rule minus,  ['-', space]
  rule star,   ['*', space]
  rule slash,  ['/', space]

  rule space,  /[ \t\n\r]*/
}
