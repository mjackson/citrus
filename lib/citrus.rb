require 'strscan'

# Citrus is a compact and powerful parsing library for Ruby that combines the
# elegance and expressiveness of the language with the simplicity and power of
# parsing expressions.
#
# http://mjijackson.com/citrus
module Citrus
  autoload :File, 'citrus/file'

  VERSION = [2, 2, 2]

  # Returns the current version of Citrus as a string.
  def self.version
    VERSION.join('.')
  end

  # A pattern to match any character, including \\n.
  DOT = /./m

  Infinity = 1.0 / 0

  CLOSE = -1

  # Loads the grammar from the given +file+ into the global scope using #eval.
  def self.load(file)
    file << '.citrus' unless ::File.file?(file)
    raise "Cannot find file #{file}" unless ::File.file?(file)
    raise "Cannot read file #{file}" unless ::File.readable?(file)
    eval(::File.read(file))
  end

  # Evaluates the given Citrus parsing expression grammar +code+ in the global
  # scope. Returns an array of any grammar modules that are created. Implicitly
  # raises +SyntaxError+ on a failed parse.
  def self.eval(code)
    parse(code, :consume => true).value
  end

  # Parses the given Citrus +code+ using the given +options+. Returns the
  # generated match tree. Raises a +SyntaxError+ if the parse fails.
  def self.parse(code, options={})
    File.parse(code, options)
  end
end

class File
  def self.here(string)
    expand_path(dirname(__FILE__)) + string
  end
end

%w{errors input memoizing_input grammar grammar_methods match rule terminal string_terminal proxy alias super
   nonterminal predicate and_predicate not_predicate but_predicate label repeat choice sequence object}.each do |lib|
  require File.here("/citrus/" + lib)
end
