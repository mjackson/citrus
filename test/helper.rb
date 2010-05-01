lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'test/unit'
require 'citrus'

class Test::Unit::TestCase
  include Citrus

  module TestGrammar
    include Citrus::Grammar

    rule(:alpha)    { /[a-z]+/i }
    rule(:num)      { /[0-9]+/ }
    rule(:alphanum) { any(:alpha, :num) }
  end

  class EqualRule < Rule
    def initialize(value)
      @value = value
    end

    def match(input, offset=0)
      create_match(@value.to_s.dup) if @value.to_s == input.string
    end
  end

  def input(str='')
    Input.new(str)
  end
end
