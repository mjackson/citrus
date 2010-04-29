lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'test/unit'
require 'citrus'

class Test::Unit::TestCase
  include Citrus

  def parser(str='')
    p = Parser.new
    p.instance_eval { @string = str }
    p
  end
end
