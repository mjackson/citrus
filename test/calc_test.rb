require File.expand_path('../helper', __FILE__)

if defined?(Calc)
  Object.__send__(:remove_const, :Calc)
end

require File.expand_path('../../examples/calc', __FILE__)

class CalcTest < Test::Unit::TestCase
  include CalcTestMethods
end
