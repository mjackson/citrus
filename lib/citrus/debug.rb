require 'citrus'
require 'builder'

module Citrus
  class Match
    # The offset at which this match was found in the input.
    attr_accessor :offset

    def debug_attrs
      { "names"   => names.join(','),
        "text"    => to_s,
        "offset"  => offset
      }
    end

    # Creates a Builder::XmlMarkup object from this match. Useful when
    # inspecting a nested match. The +xml+ argument may be a Hash of
    # Builder::XmlMarkup options.
    def to_markup(xml={})
      if Hash === xml
        opt = { :indent => 2 }.merge(xml)
        xml = Builder::XmlMarkup.new(opt)
        xml.instruct!
      end

      if matches.empty?
        xml.match(debug_attrs)
      else
        xml.match(debug_attrs) do
          matches.each {|m| m.to_markup(xml) }
        end
      end

      xml
    end

    # Returns the target of #to_markup which is an XML string unless another
    # target is specified in +opt+.
    def to_xml(opt={})
      to_markup(opt).target!
    end

    def inspect # :nodoc:
      to_xml
    end
  end

  # Hijack all classes that use Rule#create_match to create matches. Now, when
  # matches are created they will also record their offset to help debugging.
  # This functionality is included in this file because calculating the offset
  # of every match as it is created can slow things down quite a bit.
  [ Terminal,
    AndPredicate,
    NotPredicate,
    ButPredicate,
    Repeat,
    Sequence
  ].each do |rule_class|
    rule_class.class_eval do
      alias original_match match
  
      def match(input)
        m = original_match(input)
        m.offset = input.pos - m.length if m
        m
      end
    end
  end
end
