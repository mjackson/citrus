examples = File.expand_path('..', __FILE__)
$LOAD_PATH.unshift(examples) unless $LOAD_PATH.include?(examples)

# This file contains a suite of tests for the IPAddress grammar found in
# ipaddress.citrus.

require 'citrus'
Citrus.require 'ipaddress'
require 'test/unit'

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
