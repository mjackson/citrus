require 'citrus'

# Permits definition of a Citrus grammar using the global +grammar+ "keyword"
# instead of manually creating a new class that inherits Citrus::Grammar. For
# example:
#
#     class Calc < Citrus::Grammar
#     end
#
# can now be written as
#
#     Calc = grammar {
#     }
#
def grammar
  klass = Class.new(Citrus::Grammar)
  klass.class_eval(&Proc.new) if block_given?
  klass
end

# Permits the +/+ operator to be used with instances of Citrus::Rule, String,
# Regexp, Symbol, Range, and Array to create a new Citrus::Choice rule as is
# common in PEG syntax. For example:
#
#     choice(/[0-9]+/, expr)
#
# can now be written as
#
#     /[0-9]+/ / expr
#
# The notable exception is Numeric which of course already has a +/+ operator
# that should not be overridden.
[Citrus::Rule, String, Regexp, Symbol, Range, Array].each do |klass|
  klass.class_eval {
    def /(rule)
      Citrus::Choice.new([self, rule])
    end
  }
end

# Permits square brackets to be omitted when passing arrays to the following
# DSL methods as a single Sequence argument:
#
#   - rule
#   - and_predicate / and
#   - not_predicate / not
#   - one_or_more
#   - zero_or_more
#   - zero_or_one
#
# This hack works by overriding the original DSL methods with versions of each
# that convert all (trailing) arguments to arrays and then invoke the original
# with only the first element if only one is given or all elements if there are
# many. For example:
#
#     rule :prod,       [ val, one_or_more([ num, val ]) ]
#
# can now be written as
#
#     rule :prod,       val, one_or_more(num, val)
#
# The notable exception is the +repeat+ method which already has trailing
# arguments and thus requires the first argument to be an explicit array in
# order to specify a Sequence.
class Citrus::Grammar
  module SugarMethods
    def rule(name, *args)
      super(name, args.length == 1 ? args[0] : args)
    end

    %w<
    and_predicate
    and
    not_predicate
    not
    one_or_more
    zero_or_more
    zero_or_one
    >.each do |method|
      class_eval(<<-CODE.gsub(/^        /, ''), __FILE__, __LINE__ + 1)
        def #{method}(*args)
          super(args.length == 1 ? args[0] : args)
        end
      CODE
    end
  end

  class << self
    include SugarMethods
  end
end
