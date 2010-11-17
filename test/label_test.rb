require File.expand_path('../helper', __FILE__)

class LabelTest < Test::Unit::TestCase
  def test_terminal?
    rule = Label.new
    assert_equal(false, rule.terminal?)
  end

  def test_match
    abc = Rule.new('abc')
    abc.name = 'abc'
    label = Label.new(abc, 'a_label')
    label.name = 'label'
    match = label.parse('abc')
    assert(match)
    assert_equal([:abc, :a_label, :label], match.names)
  end

  def test_to_s
    rule = Label.new('a', 'label')
    assert_equal('label:"a"', rule.to_s)

    rule = Label.new(Sequence.new(%w< a b >), 'label')
    assert_equal('label:("a" "b")', rule.to_s)
  end
end
