require File.expand_path('../helper', __FILE__)

Citrus.load File.expand_path('../../examples/calc', __FILE__)

class CalcFileTest < Test::Unit::TestCase
  include CalcTestMethods

  # It's a bit hacky, but since this test runs before calc_test.rb we can
  # avoid getting the "already defined constant" error by renaming the Calc
  # constant here.
  CalcFile = Object.__send__(:remove_const, :Calc)

  def do_test(expr)
    super(expr, CalcFile)
  end
end
