require File.dirname(__FILE__) + '/helper'
Citrus.load(File.dirname(__FILE__) + '/../examples/calc')

class CalcPEGTest < Test::Unit::TestCase
  include CalcTests
end
