use strict;
use warnings;
use feature qw/state/;

use Test::More;
use B::Deparse;
use PerlX::Declare;

my @OK = (
    'let $foo'       => 'my $foo',
    'let ($foo)'     => 'my $foo', # equivalent to my ($foo)
    'let $foo:Good'  => '\'attributes\'->import(\'main\', \$foo, \'Good\'), my $foo', # my $foo:Good
    'let $foo = 123' => 'my $foo;$foo = 123',
    'let Str $foo'   => 'my $foo;ttie $foo, Str',
);

sub check {
    my ($declaration, $expected) = @_;
    state $deparse = B::Deparse->new();

    my $code = eval "sub { $declaration }";
    my $text = $deparse->coderef2text($code);
    my $got = $text =~ s!^    !!mgr;
    $got =~ s!\n!!g;

    note "'$expected'";
    note $text;
    my $e = quotemeta $expected;
    ok $got =~ m!$e!;
}
sub Str() { ;; }

for (my $i = 0; $i < @OK; $i++) {
    check($OK[$i], $OK[++$i])
}

done_testing;
