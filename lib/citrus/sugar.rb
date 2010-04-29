require 'citrus'

# Permits the +/+ operator to be used with instances of Citrus::Rule, String,
# Regexp, Range, Array, and Symbol to create a new Citrus::Choice rule as is
# common in PEG syntax. For example:
#
#     choice(/[0-9]+/, :val)
#
# can now be written as
#
#     /[0-9]+/ / :val
#
# The notable exception is Numeric which of course already has a +/+ operator
# that should not be overridden.
[Citrus::Rule, String, Regexp, Range, Array, Symbol].each do |klass|
  klass.class_eval {
    def /(rule)
      Citrus::Choice.new([self, rule])
    end
  }
end

# Permits rule names embedded within other rules to be written plainly, without
# a colon in front. For example:
#
#     sequence(:alpha, :num)
#
# can now be written as
#
#     sequence(alpha, num)
#
# This hack works by adding a +method_missing+ catch-all to the grammar DSL so
# that when methods are called that do not already exist the method name is
# returned as a symbol. The only caveat is that this will not work with names
# of methods that are already defined in the DSL or the class methods (e.g.
# "root", "rule", etc.).
module Citrus::GrammarDSL
  def method_missing(sym, *args)
    sym
  end
end
