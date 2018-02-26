use strict;
use warnings;

use Test::More;

BEGIN {
    require PerlX::Declare;

    PerlX::Declare->import;
    is $PerlX::Declare::LEVEL, $PerlX::Declare::DEFAULT_LEVEL;
    is $PerlX::Declare::DEFAULT_LEVEL, 2;

    PerlX::Declare->import(level => 0);
    is $PerlX::Declare::LEVEL, 0;

    PerlX::Declare->import(level => 1);
    is $PerlX::Declare::LEVEL, 1;

    local $ENV{'PerlX::Declare::LEVEL'} = 2;
    PerlX::Declare->import;
    is $PerlX::Declare::LEVEL, 2;

    local $ENV{'PerlX::Declare::LEVEL'} = 1;
    PerlX::Declare->import;
    is $PerlX::Declare::LEVEL, 1;

    local $ENV{'PerlX::Declare::LEVEL'} = 0;
    PerlX::Declare->import;
    is $PerlX::Declare::LEVEL, 0;
}

done_testing;
