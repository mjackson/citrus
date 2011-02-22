require File.expand_path('../helper', __FILE__)

class LeftRecursionTest < Test::Unit::TestCase
  grammar :LR do
    rule :expr do
      any(all(:expr, '-', :num),:num)
    end

    rule :num do
      /[0-9]+/
    end
  end
  
  def test_lr
    match = LR.parse("3-4-5", {:leftrecursive=>true})
    assert(match)
    assert_equal("3-4-5", match)
  end

  grammar :BigLR do
    rule :term do
      any(all(:term, '+', :fact),
          all(:term, '-', :fact),
          :fact)
    end

    rule :fact do
      any(all(:fact, '*', :num),
          all(:fact, '/', :num),
          :num)
    end

    rule :num do
      /[0-9]+/
    end
  end

  def test_big_lr
    match = BigLR.parse("3-4-5", {:leftrecursive=>true})
    assert(match)
    assert_equal("3-4-5", match)
    
    match = BigLR.parse("5*4-5", {:leftrecursive=>true})
    assert(match)
    assert_equal("5*4-5", match)
  end
end