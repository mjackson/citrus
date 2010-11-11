require File.expand_path('../helper', __FILE__)

if defined?(Calc)
  Object.__send__(:remove_const, :Calc)
end

Citrus.load File.expand_path('../../examples/calc', __FILE__)

class CalcFileTest < Test::Unit::TestCase
  include CalcTestMethods
end
