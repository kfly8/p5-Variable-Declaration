use strict;
use warnings;
use Test::More;
use Variable::Declaration;

my @OK = (
    +{
        declare         => 'my',
        is_list_context => 0,
        type_vars       => [ { var => '$foo' } ],
        attributes      => undef,
        assign          => undef,
        level           => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my $foo', 'simple',
    +{
        declare         => 'my',
        is_list_context => 1,
        type_vars       => [ { var => '$foo' } ],
        attributes      => undef,
        assign          => undef,
        level           => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my ($foo)', 'is_list_context => 1',
    +{
        declare         => 'my',
        is_list_context => 0,
        type_vars       => [ { var => '$foo' } ],
        attributes      => ':Good',
        assign          => undef,
        level           => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my $foo:Good', "attributes => ':Good'",
    +{
        declare         => 'my',
        is_list_context => 0,
        type_vars       => [ { var => '$foo' } ],
        attributes      => undef,
        assign          => "'hello'",
        level           => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my $foo;$foo = \'hello\'', "assign => 'hello'",
    +{
        declare         => 'my',
        is_list_context => 0,
        type_vars       => [ { var => '$foo', type => 'Str' } ],
        attributes      => undef,
        assign          => undef,
        level           => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my $foo;ttie $foo, Str', "type => 'Str'",
    +{
        declare         => 'my',
        is_list_context => 1,
        type_vars       => [ { var => '$foo' }, { var => '$bar' } ],
        attributes      => undef,
        assign          => undef,
        level           => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my ($foo, $bar)', "type_vars > 1",
    +{
        declare         => 'my',
        is_list_context => 1,
        type_vars       => [ { var => '$foo', type => 'Str' }, { var => '$bar' } ],
        attributes      => undef,
        assign          => undef,
        level           => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my ($foo, $bar);ttie $foo, Str', "type_vars > 1 && type => 'Str'",
    +{
        declare         => 'my',
        is_list_context => 1,
        type_vars       => [ { var => '$foo', type => 'Str' }, { var => '$bar', type => 'Int8' } ],
        attributes      => undef,
        assign          => undef,
        level           => $Variable::Declaration::DEFAULT_LEVEL,
    } => 'my ($foo, $bar);ttie $foo, Str;ttie $bar, Int8', "type_vars > 1 && set types",
    +{
        declare         => 'my',
        is_list_context => 0,
        type_vars       => [ { var => '$foo', type => 'Int' } ],
        attributes      => undef,
        assign          => 123,
        level           => 0,
    } => 'my $foo;$foo = 123', "level => 0",
    +{
        declare         => 'my',
        is_list_context => 0,
        type_vars       => [ { var => '$foo', type => 'Int' } ],
        attributes      => undef,
        assign          => 123,
        level           => 1,
    } => 'my $foo;$foo = 123;Int->get_message($foo) unless Int->check($foo)', "level => 1",
);

sub check {
    my ($args, $expected, $msg) = @_;
    my $got = Variable::Declaration::_render_declaration($args);
    note "Case: $msg";
    note "'$expected'";
    is $got, $expected;
}

while (@OK) {
    check(shift @OK, shift @OK, shift @OK);
}

done_testing;
