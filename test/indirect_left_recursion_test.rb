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
      :term
    end
    
    rule :term do
      any(all(:t, '+', :f),
          all(:t, '-', :f),
          :f)
    end
    
    rule :f do
      :fact
    end

    rule :fact do
      any(all(:f, '*', :num),
          all(:f, '/', :num),
          :num)
    end

    rule :num do
      /[0-9]+/
    end
  end

  def test_big_ilr
    match = BigILR.parse("3-4-5", {:leftrecursive=>true})
    assert(match)
    assert_equal("3-4-5", match)
    
    match = BigILR.parse("5*4-5", {:leftrecursive=>true})
    assert(match)
    assert_equal("5*4-5", match)
    
  end
  
end