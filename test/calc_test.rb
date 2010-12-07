require File.expand_path('../helper', __FILE__)

require File.expand_path('../../examples/calc', __FILE__)

class CalcTest < Test::Unit::TestCase
  include CalcTestMethods

  def do_test(expr)
    super(expr, Calc)
  end
end
