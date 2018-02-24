use strict;
use warnings;
use Test::More;
use PerlX::Declare;

my @OK = (
    +{
        declaration     => 'my',
        is_list_context => 0,
        type_vars       => [ { var => '$foo' } ],
        attributes      => undef,
        assign          => undef,
    } => 'my $foo', 'simple',
    +{
        declaration     => 'my',
        is_list_context => 1,
        type_vars       => [ { var => '$foo' } ],
        attributes      => undef,
        assign          => undef,
        use_type        => 1,
    } => 'my ($foo)', 'is_list_context => 1',
    +{
        declaration     => 'my',
        is_list_context => 0,
        type_vars       => [ { var => '$foo' } ],
        attributes      => ':Good',
        assign          => undef,
        use_type        => 1,
    } => 'my $foo:Good', "attributes => ':Good'",
    +{
        declaration     => 'my',
        is_list_context => 0,
        type_vars       => [ { var => '$foo' } ],
        attributes      => undef,
        assign          => "'hello'",
        use_type        => 1,
    } => 'my $foo;$foo = \'hello\'', "assign => 'hello'",
    +{
        declaration     => 'my',
        is_list_context => 0,
        type_vars       => [ { var => '$foo', type => 'Str' } ],
        attributes      => undef,
        assign          => undef,
        use_type        => 1,
    } => 'my $foo;ttie $foo, Str', "type => 'Str'",
    +{
        declaration     => 'my',
        is_list_context => 1,
        type_vars       => [ { var => '$foo' }, { var => '$bar' } ],
        attributes      => undef,
        assign          => undef,
        use_type        => 1,
    } => 'my ($foo, $bar)', "type_vars > 1",
    +{
        declaration     => 'my',
        is_list_context => 1,
        type_vars       => [ { var => '$foo', type => 'Str' }, { var => '$bar' } ],
        attributes      => undef,
        assign          => undef,
        use_type        => 1,
    } => 'my ($foo, $bar);ttie $foo, Str', "type_vars > 1 && type => 'Str'",
    +{
        declaration     => 'my',
        is_list_context => 1,
        type_vars       => [ { var => '$foo', type => 'Str' }, { var => '$bar', type => 'Int8' } ],
        attributes      => undef,
        assign          => undef,
        use_type        => 1,
    } => 'my ($foo, $bar);ttie $foo, Str;ttie $bar, Int8', "type_vars > 1 && set types",
    +{
        declaration     => 'my',
        is_list_context => 1,
        type_vars       => [ { var => '$foo', type => 'Str' }, { var => '$bar' } ],
        attributes      => undef,
        assign          => undef,
        use_type        => 0,
    } => 'my ($foo, $bar)', "use_type => 0",
);

sub check {
    my ($args, $expected, $msg) = @_;
    my $got = PerlX::Declare::_render_declaration($args);
    note "Case: $msg";
    note "'$expected'";
    is $got, $expected;
}

for (my $i = 0; $i < @OK; $i++) {
    check($OK[$i], $OK[++$i], $OK[++$i]);
}

done_testing;
