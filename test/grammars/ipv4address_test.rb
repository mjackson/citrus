require File.expand_path('../../helper', __FILE__)
require 'citrus/grammars'

Citrus.require 'ipv4address'

class IPv4AddressTest < Test::Unit::TestCase
  def test_dec_octet
    match = IPv4Address.parse('0', :root => :'dec-octet')
    assert(match)

    match = IPv4Address.parse('255', :root => :'dec-octet')
    assert(match)
  end

  def test_1
    match = IPv4Address.parse('0.0.0.0')
    assert(match)
    assert_equal(4, match.version)
  end

  def test_2
    match = IPv4Address.parse('255.255.255.255')
    assert(match)
    assert_equal(4, match.version)
  end

  def test_invalid
    assert_raise Citrus::ParseError do
      IPv4Address.parse('255.255.255.256')
    end
  end

  def test_invalid_short
    assert_raise Citrus::ParseError do
      IPv4Address.parse('255.255.255')
    end
  end

  def test_invalid_long
    assert_raise Citrus::ParseError do
      IPv4Address.parse('255.255.255.255.255')
    end
  end
end
