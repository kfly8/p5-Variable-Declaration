[![Build Status](https://travis-ci.org/kfly8/Variable-Declaration.svg?branch=master)](https://travis-ci.org/kfly8/Variable-Declaration) [![Coverage Status](https://img.shields.io/coveralls/kfly8/Variable-Declaration/master.svg?style=flat)](https://coveralls.io/r/kfly8/Variable-Declaration?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Variable-Declaration.svg)](https://metacpan.org/release/Variable-Declaration)
# NAME

Variable::Declaration - declare with type constraint

# SYNOPSIS

```perl
use Variable::Declaration;
use Types::Standard '-all';

# variable declaration
let $foo;      # is equivalent to `my $foo`
static $bar;   # is equivalent to `state $bar`
const $baz;    # is equivalent to `my $baz;dlock($baz)`

# with type constraint

# init case
let Str $foo = {}; # => Reference {} did not pass type constraint "Str"

# store case
let Str $foo = 'foo';
$foo = {}; # => Reference {} did not pass type constraint "Str"
```

# DESCRIPTION

Warning: This module is still new and experimental. The API may change in future versions. The code may be buggy.

Variable::Declaration provides new variable declarations, i.e. \`let\`, \`static\`, and \`const\`.

\`let\` is equivalent to \`my\` with type constraint.
\`static\` is equivalent to \`state\` with type constraint.
\`const\` is equivalent to \`let\` with data lock.

# LICENSE

Copyright (C) Kenta, Kobayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kenta, Kobayashi <kentafly88@gmail.com>
