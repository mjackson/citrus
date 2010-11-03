require File.expand_path('../helper', __FILE__)

Citrus.load(File.expand_path('../_files/super', __FILE__))
Citrus.load(File.expand_path('../_files/super2', __FILE__))

class SuperTest < Test::Unit::TestCase

  def test_terminal?
    rule = Super.new
    assert_equal(false, rule.terminal?)
  end

  def test_match
    grammar1 = Grammar.new {
      rule :a, 'a'
    }

    grammar2 = Grammar.new {
      include grammar1
      rule :a, any('b', sup)
    }

    match = grammar2.parse('b')
    assert(match)
    assert_equal('b', match)
    assert_equal(1, match.length)

    match = grammar2.parse('a')
    assert(match)
    assert_equal('a', match)
    assert_equal(1, match.length)
  end

  def test_peg
    match = SuperOneSub.parse('2')
    assert(match)

    match = SuperOneSub.parse('1')
    assert(match)
  end

  def test_nested
    grammar1 = Grammar.new {
      rule :a, 'a'
      rule :b, 'b'
    }

    grammar2 = Grammar.new {
      include grammar1
      rule :a, any(sup, :b)
      rule :b, sup
    }

    match = grammar2.parse('a')
    assert(match)
    assert_equal(:a, match.name)

    match = grammar2.parse('b')
    assert(match)
    assert_equal(:b, match.name)
  end

  def test_super_two
    m = SuperTwo.parse('1', :root => :one)
    assert(m)
    assert_equal('1', m)
    assert_equal(1, m.value)

    m = SuperTwo.parse('2', :root => :two)
    assert(m)
    assert_equal('2', m)
    assert_equal(2, m.value)

    m = SuperTwo.parse('1')
    assert(m)
    assert_equal('1', m)
    assert_equal(1000, m.value)

    m = SuperTwo.parse('2')
    assert(m)
    assert_equal('2', m)
    assert_equal(2000, m.value)
  end

  def test_to_s
    rule = Super.new
    assert_equal('super', rule.to_s)
  end

end
