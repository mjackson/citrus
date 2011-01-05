lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'test/unit'
require 'citrus'

class Test::Unit::TestCase
  include Citrus

  TestGrammar = Grammar.new do
    rule :alpha do
      /[a-zA-Z]/
    end

    rule :num do
      ext(/[0-9]/) { to_i }
    end

    rule :alphanum do
      any(:alpha, :num)
    end
  end

  Double = Grammar.new do
    include TestGrammar

    root :double

    rule :double do
      one_or_more(:num)
    end
  end

  Words = Grammar.new do
    include TestGrammar

    root :words

    rule :word do
      one_or_more(:alpha)
    end

    rule :words do
      [ :word, zero_or_more([ ' ', :word ]) ]
    end
  end
end
