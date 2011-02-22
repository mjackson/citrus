require File.expand_path('../helper', __FILE__)

class IndirectLeftRecursionTest < Test::Unit::TestCase
  def test_leftrecursived?
    assert MemoizedInput.new('').memoized?
  end

  grammar :ILR do
    rule :x do
      :expr
    end

    rule :expr do
      any(all(:x, '-', :num),:num)
    end

    rule :num do
      /[0-9]+/
    end
    root :x
  end
  
  def test_ilr
    match = ILR.parse("3-4-5", {:leftrecursive=>true})
  end
  
  grammar :BigILR do
    rule :t do
      ext(:term)
    end
    
    rule :term do
      any(all(:t, '+', :f){t.value + f.value},
          all(:t, '-', :f){t.value - f.value},
          :f)
    end
    
    rule :f do
      ext(:fa)
    end
    rule :fa do
      ext(:fact)
    end

    rule :fact do
      any(all(:f, '*', :num){f.value * num.value},
          all(:f, '/', :num){f.value / num.value},
          :num)
    end

    rule :num do
      ext(/[0-9]+/){to_i}
    end
  end

  def test_big_ilr
    match = BigILR.parse("3-4-5", {:leftrecursive=>true})
    assert(match)
    assert_equal("3-4-5", match)
    assert_equal(-6, match.value)
    
    match = BigILR.parse("5*4*2-5*9*2", {:leftrecursive=>true})
    assert(match)
    assert_equal("5*4*2-5*9*2", match)
    assert_equal(-50, match.value)
  end
  
end