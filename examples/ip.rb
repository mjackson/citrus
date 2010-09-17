require 'citrus'

# This file contains a small suite of tests for the grammars found in ip.citrus.
# If this file is run directly (i.e. using `ruby ip.rb') the tests will run.
# Otherwise, this file may be required by another that needs access to the IP
# address grammars just as any other file would be.

# Load and evaluate the grammars contained in ip.citrus into the global
# namespace.
Citrus.load(File.expand_path('../ip', __FILE__))

if $0 == __FILE__
  require 'test/unit'

  class IPAddressTest < Test::Unit::TestCase
    def test_dec_octet
      match = IPv4Address.parse('0', :root => :'dec-octet')
      assert(match)

      match = IPv4Address.parse('255', :root => :'dec-octet')
      assert(match)
    end

    def test_hexdig
      match = IPv6Address.parse('0', :root => :HEXDIG)
      assert(match)

      match = IPv6Address.parse('A', :root => :HEXDIG)
      assert(match)
    end

    def test_v4
      match = IPv4Address.parse('0.0.0.0')
      assert(match)

      match = IPv4Address.parse('255.255.255.255')
      assert(match)

      assert_raise Citrus::ParseError do
        IPv4Address.parse('255.255.255')
      end
    end

    def test_v6
      match = IPv6Address.parse('1:2:3:4:5:6:7:8')
      assert(match)

      match = IPv6Address.parse('12AD:34FC:A453:1922::')
      assert(match)

      match = IPv6Address.parse('12AD::34FC')
      assert(match)

      match = IPv6Address.parse('12AD::')
      assert(match)

      match = IPv6Address.parse('::')
      assert(match)

      assert_raise Citrus::ParseError do
        IPv6Address.parse('1:2')
      end
    end

    def test_all
      match = IPAddress.parse('1.2.3.4')
      assert(match)
      assert_equal(4, match.version)

      match = IPAddress.parse('1:2:3:4::')
      assert(match)
      assert_equal(6, match.version)
    end
  end
end
