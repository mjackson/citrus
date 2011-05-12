require File.expand_path('../../helper', __FILE__)
require 'citrus/grammars'

Citrus.require 'ipaddress'

class IPAddressTest < Test::Unit::TestCase
  def test_v4
    match = IPAddress.parse('1.2.3.4')
    assert(match)
    assert_equal(4, match.version)
  end

  def test_v6
    match = IPAddress.parse('1:2:3:4::')
    assert(match)
    assert_equal(6, match.version)
  end
end
