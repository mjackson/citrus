require File.expand_path('../../helper', __FILE__)
require 'citrus/grammars'

Citrus.require 'uri'

class UniformResourceIdentifierTest < Test::Unit::TestCase
  U = UniformResourceIdentifier

  def test_uri
    match = U.parse('http://www.example.com')
    assert(match)
  end

  def test_uri_with_query_string
    match = U.parse('http://www.example.com/?q=some+query')
    assert(match)
  end

  def test_authority
    match = U.parse('michael@', :root => :authority)
    assert(match)
  end

  def test_host
    match = U.parse('127.0.0.1', :root => :host)
    assert(match)

    match = U.parse('[12AD:34FC:A453:1922::]', :root => :host)
    assert(match)
  end

  def test_userinfo
    match = U.parse('michael', :root => :userinfo)
    assert(match)

    assert_raise(Citrus::ParseError) do
      U.parse('michael@', :root => :userinfo)
    end
  end

  def test_ipliteral
    match = U.parse('[12AD:34FC:A453:1922::]', :root => :'IP-literal')
    assert(match)
  end

  def test_ipvfuture
    match = U.parse('v1.123:456:789', :root => :IPvFuture)
    assert(match)

    match = U.parse('v5A.ABCD:1234', :root => :IPvFuture)
    assert(match)
  end
end
