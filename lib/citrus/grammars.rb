# Require this file to use any of the bundled Citrus grammars.
#
#     require 'citrus/grammars'
#     Citrus.require 'uri'
#
#     match = UniformResourceIdentifier.parse(uri_string)
#     # => #<Citrus::Match ... >

require 'citrus'

$LOAD_PATH.unshift(::File.expand_path('../grammars', __FILE__))
