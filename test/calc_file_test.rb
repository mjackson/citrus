require File.dirname(__FILE__) + '/helper'

if defined?(Calc)
  Object.__send__(:remove_const, :Calc)
end

Citrus.load(File.dirname(__FILE__) + '/../examples/calc')

class CalcFileTest < Test::Unit::TestCase
  include CalcTests
end
