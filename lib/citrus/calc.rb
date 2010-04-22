require 'citrus'

module Citrus

  # A grammar for simple maths.
  class Calc < Grammar

    ignore /[ \t\s\n]+/

    root :expr

    rule(:digit)        { 0..9 }
    rule(:num)          { one_or_more digit }

    rule(:expr)         { any term, add_expr }
    rule(:bracket_expr) { ['(', expr, ')'] }
    rule(:term)         { any factor, mult_expr }
    rule(:factor)       { any num, bracket_expr }
    rule(:mult_expr)    { [term, mult_op, factor] }
    rule(:add_expr)     { [expr, add_op, term] }
    rule(:mult_op)      { any '/', '*' }
    rule(:add_op)       { any '+', '-' }

    #rule(:expr)         { [factor, expr_tail] }
    #rule(:expr_tail)    { any ['+', factor], ['-', factor] }
    #rule(:factor)       { [term, factor_tail] }
    #rule(:factor_tail)  { any ['*', term], ['/', term] }
    #rule(:term)         { any num, ['(', expr, ')'] }

  end
end
