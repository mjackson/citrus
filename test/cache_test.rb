require File.expand_path('../helper', __FILE__)

class CacheTest < Test::Unit::TestCase

  LetterA = Grammar.new do
    rule :top do
      any(:three_as, :two_as, :one_a)
    end

    rule :three_as do
      rep(:one_a, 3, 3)
    end

    rule :two_as do
      rep(:one_a, 2, 2)
    end

    rule :one_a do
      "a"
    end
  end

  def test_cache_hits
    top = LetterA.rule(:top)

    input = Input.new('a')
    input.memoize!
    match = input.match(top)
    assert(match)
    assert_equal(2, input.cache_hits)

    input = Input.new('aa')
    input.memoize!
    match = input.match(top)
    assert(match)
    assert_equal(2, input.cache_hits)

    input = Input.new('aaa')
    input.memoize!
    match = input.match(top)
    assert(match)
    assert_equal(0, input.cache_hits)
  end

end
