# Background


In order to be able to use Citrus effectively, you must first understand the
difference between syntax and semantics. Syntax is a set of rules that govern
the way letters and punctuation may be used in a language. For example, English
syntax dictates that proper nouns should start with a capital letter and that
sentences should end with a period.

Semantics are the rules by which meaning may be derived in a language. For
example, as you read a book you are able to make some sense of the particular
way in which words on a page are combined to form thoughts and express ideas
because you understand what the words themselves mean and you understand what
they mean collectively.

Computers use a similar process when interpreting code. First, the code must be
parsed into recognizable symbols or tokens. These tokens may then be passed to
an interpreter which is responsible for forming actual instructions from them.

Citrus is a pure Ruby library that allows you to perform both lexical analysis
and semantic interpretation quickly and easily. Using Citrus you can write
powerful parsers that are simple to understand and easy to create and maintain.

In Citrus, there are three main types of objects: rules, grammars, and matches.

## Rules

A [Rule](api/classes/Citrus/Rule.html) is an object that specifies some matching
behavior on a string. There are two types of rules: terminals and non-terminals.
Terminals can be either Ruby strings or regular expressions that specify some
input to match. For example, a terminal created from the string "end" would
match any sequence of the characters "e", "n", and "d", in that order. Terminals
created from regular expressions may match any sequence of characters that can
be generated from that expression.

Non-terminals are rules that may contain other rules but do not themselves match
directly on the input. For example, a Repeat is a non-terminal that may contain
one other rule that will try and match a certain number of times. Several other
types of non-terminals are available that will be discussed later.

Rule objects may also have semantic information associated with them in the form
of Ruby modules. Rules use these modules to extend the matches they create.

## Grammars

A grammar is a container for rules. Usually the rules in a grammar collectively
form a complete specification for some language, or a well-defined subset
thereof.

A Citrus grammar is really just a souped-up Ruby
[module](http://ruby-doc.org/core/classes/Module.html). These modules may be
included in other grammar modules in the same way that Ruby modules are normally
used. This property allows you to divide a complex grammar into more manageable, 
reusable pieces that may be combined at runtime. Any grammar rule with the same 
name as a rule in an included grammar may access that rule with a mechanism 
similar to Ruby's super keyword.

## Matches

Matches are created by rule objects when they match on the input. A 
[Match](api/classes/Citrus/Match.html) is actually a 
[String](http://ruby-doc.org/core/classes/String.html) object with some extra 
information attached such as the name(s) of the rule(s) from which it was
generated and any submatches it may contain.

During a parse, matches are arranged in a tree structure where any match may
contain any number of other matches. This structure is determined by the way in
which the rule that generated each match is used in the grammar. For example, a 
match that is created from a non-terminal rule that contains several other 
terminals will likewise contain several matches, one for each terminal.

Match objects may be extended with semantic information in the form of methods.
These methods should provide various interpretations for the semantic value of a
match.
