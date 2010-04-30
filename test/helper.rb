lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'test/unit'
require 'citrus'

class Test::Unit::TestCase
  include Citrus

  TestGrammar = Grammar.new {
    rule(:num)      { /[0-9]+/ }
    rule(:alpha)    { /[a-z]+/i }
    rule(:alphanum) { any(:alpha, :num) }
  }

  def input(str='')
    Input.new(str)
  end
end
