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

our $LEVEL;
our $DEFAULT_LEVEL = 2;

sub import {
    shift;
    my %args = @_;
    my $caller = caller;

    $LEVEL = exists $args{level} ? $args{level}
           : exists $ENV{'PerlX::Declare::LEVEL'} ? $ENV{'PerlX::Declare::LEVEL'}
           : $DEFAULT_LEVEL;

    feature->import::into($caller, 'state');
    Data::Lock->import::into($caller, 'dlock');
    Type::Tie->import::into($caller, 'ttie');

    Keyword::Simple::define 'let'    => \&define_let;
    Keyword::Simple::define 'static' => \&define_static;
    Keyword::Simple::define 'const'  => \&define_const;
}

sub unimport {
    Keyword::Simple::undefine 'let';
    Keyword::Simple::undefine 'static';
    Keyword::Simple::undefine 'const';
}

sub define_let { define_declaration(let => 'my', @_) }
sub define_static { define_declaration(static => 'state', @_) }

sub define_declaration {
    my ($keyword, $declare, $ref) = @_;

    my $m = _parse($$ref);
    Carp::croak "variable declaration is required" unless $m->{type_varlist};
    Carp::croak "illegal expression"               unless ($m->{eq} && $m->{assign}) or (!$m->{eq} && !$m->{assign});

    my $tv   = _parse_type_varlist($m->{type_varlist});
    my $args = +{ declare => $declare, %$m, %$tv, level => $LEVEL };

    my $declaration = _render_declaration($args);
    substr($$ref, 0, length $m->{statement}) = $declaration;
}

sub define_const {
    my $ref = shift;

    my $m = _parse($$ref);
    Carp::croak "variable declaration is required'"    unless $m->{type_varlist};
    Carp::croak "'const' declaration must be assigned" unless $m->{eq} && $m->{assign};

    my $tv   = _parse_type_varlist($m->{type_varlist});
    my $args = +{ declare => 'my', %$m, %$tv, level => $LEVEL };

    my $declaration = _render_declaration($args);
    my $data_lock   = _render_data_lock($args);
    substr($$ref, 0, length $m->{statement}) = sprintf('%s; %s', $declaration, $data_lock);
}

sub _render_declaration {
    my $args = shift;
    my @lines;
    push @lines => _lines_dec($args);
    push @lines => _lines_type_tie($args)                if $args->{level} == 2;
    push @lines => "@{[__dec($args)]} = $args->{assign}" if $args->{assign};
    push @lines => _lines_type_check($args)              if $args->{level} == 1;
    return join ";", @lines;
}

sub __dec {
    my $args = shift;
    my $dec = join ', ', map { $_->{var} } @{$args->{type_vars}};
    if ($args->{is_list_context}) {
        $dec = "($dec)"
    }
    return $dec;
}

sub _lines_dec {
    my $args = shift;
    my @lines;
    push @lines => sprintf('%s %s%s', $args->{declare}, __dec($args), $args->{attributes}||'');
    return @lines;
}

sub _lines_type_tie {
    my $args = shift;
    my @lines;
    for (@{$args->{type_vars}}) {
        my ($type, $var) = ($_->{type}, $_->{var});
        next unless $type;
        push @lines => sprintf('ttie %s, %s', $var, $type);
    }
    return @lines;
}

sub _lines_type_check {
    my $args = shift;
    my @lines;
    for (@{$args->{type_vars}}) {
        my ($type, $var) = ($_->{type}, $_->{var});
        next unless $type;
        push @lines => sprintf('%s->get_message(%s) unless %s->check(%s)', $type, $var, $type, $var)
    }
    return @lines;
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

    return unless $src =~ m{
        \A
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
        ) $PPR::GRAMMAR }x;

    return +{
        statement       => $+{statement},
        type_varlist    => $+{type_varlist},
        assign_to       => $+{assign_to},
        eq              => $+{eq},
        assign          => $+{assign},
        attributes      => $+{attributes},
    }
}

sub _parse_type_varlist {
    my $expression = shift;

    if ($expression =~ m{ (?<list>(?&PerlParenthesesList)) $PPR::GRAMMAR }x) {
        my @list = split ',', $+{list} =~ s/\A\((.+)\)\Z/$1/r;
        return +{
            is_list_context => 1,
            type_vars       => [ map { _parse_type_var($_) } @list ],
        }
    }
    elsif (my $type_var = _parse_type_var($expression)) {
        return +{
            is_list_context => 0,
            type_vars       => [ $type_var ],
        }
    }
    else {
        return;
    }
}

sub _parse_type_var {
    my $expression = shift;

    return unless $expression =~ m{
        \A
        (?&PerlOWS)
        (?<type>(?&PerlIdentifier))? (?&PerlOWS)
        (?<var>(?:(?&PerlVariable)))
        \Z
        $PPR::GRAMMAR
    }x;

    return +{
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

