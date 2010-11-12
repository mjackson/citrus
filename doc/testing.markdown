# Testing


Citrus was designed to facilitate simple and powerful testing of grammars. To
demonstrate how this is to be done, we'll use the `Addition` grammar from our
previous [example](example.html). The following code demonstrates a simple test
case that could be used to test that our grammar works properly.

    class AdditionTest < Test::Unit::TestCase
      def test_additive
        match = Addition.parse('23 + 12', :root => :additive)
        assert(match)
        assert_equal('23 + 12', match)
        assert_equal(35, match.value)
      end

      def test_number
        match = Addition.parse('23', :root => :number)
        assert(match)
        assert_equal('23', match)
        assert_equal(23, match.value)
      end
    end

The key here is using the `:root` option when performing the parse to specify
the name of the rule at which the parse should start. In `test_number`, since
`:number` was given the parse will start at that rule as if it were the root
rule of the entire grammar. The ability to change the root rule on the fly like
this enables easy unit testing of the entire grammar.

Also note that because match objects are themselves strings, assertions may be
made to test equality of match objects with string values.

## Debugging

When a parse fails, a [ParseError](api/classes/Citrus/ParseError.html) object is
generated which provides a wealth of information about exactly where the parse
failed including the offset, line number, line text, and line offset. Using this
object, you could possibly provide some useful feedback to the user about why
the input was bad. The following code demonstrates one way to do this.

    def parse_some_stuff(stuff)
      match = StuffGrammar.parse(stuff)
    rescue Citrus::ParseError => e
      raise ArgumentError, "Invalid stuff on line %d, offset %d!" %
        [e.line_number, e.line_offset]
    end

In addition to useful error objects, Citrus also includes a means of visualizing
match trees in the console via `Match#dump`. This can help when determining
which rules are generating which matches and how they are organized in the
match tree.
