package Variable::Declaration;
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
           : exists $ENV{'Variable::Declaration::LEVEL'} ? $ENV{'Variable::Declaration::LEVEL'}
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

sub define_let    { define_declaration(let => 'my', @_) }
sub define_static { define_declaration(static => 'state', @_) }
sub define_const  { define_declaration(const => 'my', @_) }

sub define_declaration {
    my ($keyword, $perl_keyword, $ref) = @_;

    my $m    = _valid($keyword => _parse($$ref));
    my $tv   = _parse_type_varlist($m->{type_varlist});
    my $args = +{ keyword => $keyword, perl_keyword => $perl_keyword, %$m, %$tv, level => $LEVEL };

    substr($$ref, 0, length $m->{statement}) = _render_declaration($args);
}

sub _valid {
    my ($keyword, $m) = @_;

    Carp::croak "variable declaration is required'" if !$m->{type_varlist};
    Carp::croak "'const' declaration must be assigned" if $keyword eq 'const' && !(defined $m->{eq} && defined $m->{assign});
    Carp::croak "illegal expression" if $keyword ne 'const' && !((defined $m->{eq} && defined $m->{assign}) or (!defined $m->{eq} && !defined $m->{assign}));

    return $m;
}

sub _render_declaration {
    my $args = shift;

    my @lines;
    push @lines => _lines_declaration($args);
    push @lines => _lines_type_check($args) if $args->{level} >= 1;
    push @lines => _lines_type_tie($args)   if $args->{level} == 2;
    push @lines => _lines_data_lock($args)  if $args->{keyword} eq 'const';

    return join ";", @lines;
}

sub _lines_declaration {
    my $args = shift;
    my $s = $args->{perl_keyword};
    $s .= do {
        my $s = join ', ', map { $_->{var} } @{$args->{type_vars}};
        $args->{is_list_context} ? " ($s)" : " $s";
    };
    $s .= $args->{attributes} if $args->{attributes};
    $s .= " = @{[$args->{assign}]}" if defined $args->{assign};
    return ($s);
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

sub _lines_data_lock {
    my $args = shift;
    my @lines;
    for my $type_var (@{$args->{type_vars}}) {
        push @lines => "dlock($type_var->{var})";
    }
    return @lines;
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

Variable::Declaration - add type declaration syntax

=head1 SYNOPSIS

    use Variable::Declaration;
    use Types::Standard qw/Str/;

    let Str $foo = 'foo';
    const Str $bar = 'bar';

=head1 DESCRIPTION

Variable::Declaration is ...

=head1 LICENSE

Copyright (C) Kenta, Kobayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kenta, Kobayashi E<lt>kentafly88@gmail.comE<gt>

=cut

