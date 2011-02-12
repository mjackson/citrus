require File.expand_path('../helper', __FILE__)

class MemoizedInputTest < Test::Unit::TestCase
  def test_memoized?
    assert MemoizedInput.new('').memoized?
  end

  grammar :LetterA do
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

  def test_cache_hits1
    input = MemoizedInput.new('a')
    input.exec(LetterA.rule(:top))
    assert_equal(3, input.cache_hits)
  end

  def test_cache_hits2
    input = MemoizedInput.new('aa')
    input.exec(LetterA.rule(:top))
    assert_equal(2, input.cache_hits)
  end

  def test_cache_hits3
    input = MemoizedInput.new('aaa')
    input.exec(LetterA.rule(:top))
    assert_equal(0, input.cache_hits)
  end
  
  grammar :LettersABC do
    rule :top do
      any(all(:a,:b,:c), all(:b,:a,:c), all(:b,:c,:a))
    end
    rule :a do
      "a"
    end
    rule :b do
      "b"
    end
    rule :c do
      "c"
    end
  end

  def test_memoization
    match = LettersABC.parse('bca',{:memoize=>true})
    assert_equal('bca',match)
  end 

end
