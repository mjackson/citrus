# Syntax


The most straightforward way to compose a Citrus grammar is to use Citrus' own
custom grammar syntax. This syntax borrows heavily from Ruby, so it should
already be familiar to Ruby programmers.

## Terminals

Terminals may be represented by a string or a regular expression. Both follow
the same rules as Ruby string and regular expression literals.

    'abc'
    "abc\n"
    /\xFF/

Character classes and the dot (match anything) symbol are supported as well for
compatibility with other parsing expression implementations.

    [a-z0-9]      # match any lowercase letter or digit
    [\x00-\xFF]   # match any octet
    .             # match anything, even new lines

See [FixedWidth](api/classes/Citrus/FixedWidth.html) and
[Expression](api/classes/Citrus/Expression.html) for more information.

## Repetition

Quantifiers may be used after any expression to specify a number of times it
must match. The universal form of a quantifier is N*M where N is the minimum and
M is the maximum number of times the expression may match.

    'abc'1*2      # match "abc" a minimum of one, maximum
                  # of two times
    'abc'1*       # match "abc" at least once
    'abc'*2       # match "abc" a maximum of twice

The + and ? operators are supported as well for the common cases of 1* and *1
respectively.

    'abc'+        # match "abc" at least once
    'abc'?        # match "abc" a maximum of once

See [Repeat](api/classes/Citrus/Repeat.html) for more information.

## Lookahead

Both positive and negative lookahead are supported in Citrus. Use the & and !
operators to indicate that an expression either should or should not match. In
neither case is any input consumed.

    &'a' 'b'      # match a "b" preceded by an "a"
    !'a' 'b'      # match a "b" that is not preceded by an "a"
    !'a' .        # match any character except for "a"

A special form of lookahead is also supported which will match any character
that does not match a given expression.

    ~'a'          # match all characters until an "a"
    ~/xyz/        # match all characters until /xyz/ matches

See [AndPredicate](api/classes/Citrus/AndPredicate.html),
[NotPredicate](api/classes/Citrus/NotPredicate.html), and
[ButPredicate](api/classes/Citrus/ButPredicate.html) for more information.

## Sequences

Sequences of expressions may be separated by a space to indicate that the rules
should match in that order.

    'a' 'b' 'c'   # match "a", then "b", then "c"
    'a' [0-9]     # match "a", then a numeric digit

See [Sequence](api/classes/Citrus/Sequence.html) for more information.

## Choices

Ordered choice is indicated by a vertical bar that separates two expressions.
Note that any operator binds more tightly than the bar.

    'a' | 'b'       # match "a" or "b"
    'a' 'b' | 'c'   # match "a" then "b" (in sequence), or "c"

See [Choice](api/classes/Citrus/Choice.html) for more information.

## Super

When including a grammar inside another, all rules in the child that have the
same name as a rule in the parent also have access to the "super" keyword to
invoke the parent rule.

See [Super](api/classes/Citrus/Super.html) for more information.

## Labels

Match objects may be referred to by a different name than the rule that
originally generated them. Labels are created by placing the label and a colon
immediately preceding any expression.

    chars:/[a-z]+/  # the characters matched by the regular
                    # expression may be referred to as "chars"
                    # in a block method

See [Label](api/classes/Citrus/Label.html) for more information.

## Precedence

The following table contains a list of all Citrus operators and their 
precedence. A higher precedence indicates tighter binding.

| Operator     | Name                      | Precedence
| ------------ | ------------------------- | ----------
| ''           | String (single quoted)    | 6
| ""           | String (double quoted)    | 6
| []           | Character class           | 6
| .            | Dot (any character)       | 6
| //           | Regular expression        | 6
| ()           | Grouping                  | 6
| *            | Repetition (arbitrary)    | 5
| +            | Repetition (one or more)  | 5
| ?            | Repetition (zero or one)  | 5
| &            | And predicate             | 4
| !            | Not predicate             | 4
| ~            | But predicate             | 4
| :            | Label                     | 4
| <>           | Extension (module name)   | 3
| {}           | Extension (literal)       | 3
| e1 e2        | Sequence                  | 2
| e1 &#124; e2 | Ordered choice            | 1
