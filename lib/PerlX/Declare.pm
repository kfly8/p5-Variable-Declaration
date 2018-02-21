package PerlX::Declare;
use v5.12.0;
use strict;
use warnings;

our $VERSION = "0.01";

use Keyword::Simple;
use PPR;
use Carp ();
use Import::Into;
use Data::Lock ();
use Type::Tie ();

sub import {
    my $caller = caller;

    Data::Lock->import::into($caller, 'dlock');
    Type::Tie->import::into($caller);

    Keyword::Simple::define 'let' => \&define_let;
    Keyword::Simple::define 'const' => \&define_const;
}

sub unimport {
    Keyword::Simple::undefine 'let';
    Keyword::Simple::undefine 'const';
}

sub define_let {
    my $ref = shift;

    my $m = _parse($$ref);
    Carp::croak "syntax error near 'let'" unless $m->{statement};
    Carp::croak "illegal expression" unless ($m->{eq} && $m->{assign}) or (!$m->{eq} && !$m->{assign});

    my $tv = _parse_type_varlist($m->{type_varlist});
    Carp::croak "variable declaration is required'" unless grep { $_->{var} } @{$tv->{type_vars}};

    substr($$ref, 0, length $m->{statement}) = _render_let({%$m, %$tv});
}

sub define_const {
    my $ref = shift;

    my $m = _parse($$ref);
    Carp::croak "syntax error near 'const'" unless $m->{statement};
    Carp::croak "'const' declaration must be assigned" unless $m->{eq} && $m->{assign};

    my $tv = _parse_type_varlist($m->{type_varlist});
    Carp::croak "variable declaration is required'" unless grep { $_->{var} } @{$tv->{type_vars}};

    substr($$ref, 0, length $m->{statement}) = _render_const({%$m, %$tv});
}

sub _required_type_check { 1 }

sub _render_let {
    my $args = shift;
    my $declaration = _render_declaration($args);
    return sprintf('%s', $declaration);
}

sub _render_const {
    my $args = shift;
    my $declaration = _render_declaration($args);
    my $data_lock   = _render_data_lock($args);
    return sprintf('%s; %s', $declaration, $data_lock);
}

sub _render_declaration {
    my $args = shift;
    my @lines;

    my $dec = join ', ', map { $_->{var} } @{$args->{type_vars}};
    if ($args->{is_list_context}) {
        $dec = "($dec)"
    }
    push @lines => "my $dec @{[$args->{attributes}||'']}";

    if (_required_type_check()) {
        for my $type_var (@{$args->{type_vars}}) {
            if ($type_var->{type}) {
                push @lines => "ttie $type_var->{var}, $type_var->{type}";
            }
        }
    }

    if ($args->{assign}) {
        push @lines => "$dec = $args->{assign}";
    }

    return join ";", @lines;
}

sub _render_data_lock {
    my $args = shift;
    my @lines;
    for my $type_var (@{$args->{type_vars}}) {
        push @lines => "dlock($type_var->{var})";
    }
    return join ';', @lines;
}

sub _parse {
    my $src = shift;

    $src =~ m{
        (?<statement>
            (?&PerlOWS)
            (?<assign_to>
                (?<type_varlist>
                    (?&PerlIdentifier)? (?&PerlOWS)
                    (?&PerlVariable)
                |   (?&PerlParenthesesList)
                ) (?&PerlOWS)
                (?<attributes>(?&PerlAttributes))? (?&PerlOWS)
            )
            (?<eq>=)? (?&PerlOWS)
            (?<assign>(?&PerlConditionalExpression))?
        )
        $PPR::GRAMMAR }x;

    return {
        statement       => $+{statement},
        type_varlist    => $+{type_varlist},
        assign_to       => $+{assign_to},
        eq              => $+{eq},
        assign          => $+{assign},
        attributes      => $+{attributes},
    }
}

sub _parse_type_varlist {
    my $type_varlist = shift;

    $type_varlist =~ m{ (?<list>(?&PerlParenthesesList)) $PPR::GRAMMAR }x;
    my $is_list_context = $+{list} ? 1 : 0;
    my $type_vars       = $+{list} ? [ map { _parse_type_var($_) } split ',', $+{list} ]
                        : [ _parse_type_var($type_varlist) ];

    return {
        is_list_context => $is_list_context,
        type_vars       => $type_vars,
    }
}

sub _parse_type_var {
    my $type_var = shift;

    $type_var =~ m{
        (?<type>(?&PerlIdentifier))? (?&PerlOWS)
        (?<var>(?&PerlVariable)) (?&PerlOWS)
        $PPR::GRAMMAR
    }x;

    return {
        type => $+{type},
        var  => $+{var},
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

PerlX::Declare - add type declaration syntax

=head1 SYNOPSIS

    use PerlX::Declare;
    use Types::Standard qw/Str/;

    let Str $foo = 'foo';
    const Str $bar = 'bar';

=head1 DESCRIPTION

PerlX::Declare is ...

=head1 LICENSE

Copyright (C) Kenta, Kobayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kenta, Kobayashi E<lt>kentafly88@gmail.comE<gt>

=cut

