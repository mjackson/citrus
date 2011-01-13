# encoding: UTF-8

require File.expand_path('../helper', __FILE__)

class MultibyteTest < Test::Unit::TestCase
  grammar :Multibyte do
    rule :string do
      "ä"
    end

    rule :regexp do
      /(ä)+/
    end

    rule :character_class do
      /[ä]+/
    end
  end

  def test_multibyte_string
    m = Multibyte.parse("ä", :root => :string)
    assert(m)
  end

  def test_multibyte_regexp
    m = Multibyte.parse("äää", :root => :regexp)
    assert(m)
  end

  def test_multibyte_character_class
    m = Multibyte.parse("äää", :root => :character_class)
    assert(m)
  end

  Citrus.eval(<<-CITRUS)
  grammar Multibyte2
    rule string
      "ä"
    end

    rule regexp
      /(ä)+/
    end

    rule character_class
      [ä]+
    end
  end
  CITRUS

  def test_multibyte2_string
    m = Multibyte2.parse("ä", :root => :string)
    assert(m)
  end

  def test_multibyte2_regexp
    m = Multibyte2.parse("äää", :root => :regexp)
    assert(m)
  end

  def test_multibyte2_character_class
    m = Multibyte2.parse("äää", :root => :character_class)
    assert(m)
  end
end
