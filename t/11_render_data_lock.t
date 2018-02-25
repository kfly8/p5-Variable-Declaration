use strict;
use warnings;
use Test::More;
use PerlX::Declare;

my @OK = (
    [ { var => '$foo' } ]
    => 'dlock($foo)',
    [ { var => '$foo' }, { var => '$bar' } ]
    => 'dlock($foo);dlock($bar)',
);

sub check {
    my ($type_vars, $expected) = @_;
    my $got = PerlX::Declare::_render_data_lock({ type_vars => $type_vars });
    note "'$expected'";
    is $got, $expected;
}

while (@OK) {
    check(shift @OK, shift @OK);
}

done_testing;
