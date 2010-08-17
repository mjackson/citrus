require File.expand_path('../helper', __FILE__)

class MultibyteTest < Test::Unit::TestCase
  Citrus.eval(<<-'CODE')
  grammar MultibyteTest::Grammar
    rule string
      "\xFF"
    end

    rule regexp
      /\xFF/
    end

    rule character_class
      [\xFF]
    end
  end
  CODE

  def test_multibyte_string
    m = Grammar.parse("\xFF", :root => :string)
    assert(m)
  end

  def test_multibyte_regexp
    m = Grammar.parse("\xFF", :root => :regexp)
    assert(m)
  end

  def test_multibyte_character_class
    m = Grammar.parse("\xFF", :root => :character_class)
    assert(m)
  end
end
