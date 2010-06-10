require 'citrus'
require 'builder'

module Citrus
  class Match
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
        xml.match("name" => name, "text" => text, "offset" => offset)
      else
        xml.match("name" => name, "text" => text, "offset" => offset) do
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
end
