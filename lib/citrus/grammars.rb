# Require this file to use any of the bundled Citrus grammars.
#
#     require 'citrus/grammars'
#     Citrus.require 'uri'
#
#     match = UniformResourceIdentifier.parse(uri_string)
#     # => #<Citrus::Match ... >

require 'citrus'

grammars = ::File.expand_path(::File.join('..', 'grammars'), __FILE__)
$LOAD_PATH.unshift(grammars) unless $LOAD_PATH.include?(grammars)
