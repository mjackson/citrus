require File.expand_path('../helper', __FILE__)

class LabelTest < Test::Unit::TestCase
  # def test_terminal?
  #   rule = Label.new
  #   assert_equal(false, rule.terminal?)
  # end
  # 
  # def test_match
  #   abc = Rule.for('abc')
  #   abc.name = 'abc'
  #   label = Label.new(abc, 'a_label')
  #   label.name = 'label'
  #   match = label.parse('abc')
  #   assert(match)
  #   assert_equal([:abc, :a_label, :label], match.names)
  # end

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
