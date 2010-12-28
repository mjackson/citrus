require File.expand_path('../helper', __FILE__)

class LabelTest < Test::Unit::TestCase
  def test_to_s
    rule = Rule.for('a')
    rule.label = 'a_label'
    assert_equal('a_label:"a"', rule.to_s)
  end

  def test_to_s_sequence
    rule = Sequence.new(%w< a b >)
    rule.label = 's_label'
    assert_equal('s_label:("a" "b")', rule.to_s)
  end

  def test_to_s_embedded
    a = Rule.for('a')
    a.label = 'a_label'
    rule = Sequence.new([ a, 'b' ])
    rule.label = 's_label'
    assert_equal('s_label:(a_label:"a" "b")', rule.to_s)
  end
end
