require File.dirname(__FILE__) + '/helper'

if defined?(Calc)
  Object.__send__(:remove_const, :Calc)
end

require File.dirname(__FILE__) + '/../examples/calc'

class CalcTest < Test::Unit::TestCase
  include CalcTests
end
