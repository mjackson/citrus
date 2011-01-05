examples = File.expand_path('..', __FILE__)
$LOAD_PATH.unshift(examples) unless $LOAD_PATH.include?(examples)

# This file contains a suite of tests for the IPv6Address grammar found in
# ipv6address.citrus.

require 'citrus'
Citrus.require 'ipv6address'
require 'test/unit'

class IPv6AddressTest < Test::Unit::TestCase
  def test_hexdig
    match = IPv6Address.parse('0', :root => :HEXDIG)
    assert(match)

    match = IPv6Address.parse('A', :root => :HEXDIG)
    assert(match)
  end

  def test_1
    match = IPv6Address.parse('1:2:3:4:5:6:7:8')
    assert(match)
    assert_equal(6, match.version)
  end

  def test_2
    match = IPv6Address.parse('12AD:34FC:A453:1922::')
    assert(match)
    assert_equal(6, match.version)
  end

  def test_3
    match = IPv6Address.parse('12AD::34FC')
    assert(match)
    assert_equal(6, match.version)
  end

  def test_4
    match = IPv6Address.parse('12AD::')
    assert(match)
    assert_equal(6, match.version)
  end

  def test_5
    match = IPv6Address.parse('::')
    assert(match)
    assert_equal(6, match.version)
  end

  def test_invalid
    assert_raise Citrus::ParseError do
      IPv6Address.parse('1:2')
    end
  end
end
