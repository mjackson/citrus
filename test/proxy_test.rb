require File.dirname(__FILE__) + '/helper'

class ProxyTest < Test::Unit::TestCase

  def test_terminal?
    rule = Proxy.new
    assert_equal(false, rule.terminal?)
  end

  def test_to_s
    rule = Proxy.new(:alpha)
    assert_equal('alpha', rule.to_s)
  end

end
