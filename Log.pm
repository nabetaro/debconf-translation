#!/usr/bin/perl

=head1 NAME

Debian::DebConf::Log -- debconf log module

=cut

=head1 DESCRIPTION

This is a log module for debconf. It can output messages at varying priorities.

This module uses Exporter.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Log;
use Exporter;
use strict;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);

@ISA = qw(Exporter);
@EXPORT_OK=qw(debug warn);
# Import :all to get everything.
%EXPORT_TAGS = (all => [@EXPORT_OK]);

=head2 debug

Outputs an infomational message, if DEBCONF_DEBUG is set in the environment.

=cut

sub debug {
	print STDERR "debconf: ".join(" ", @_)."\n" if $ENV{DEBCONF_DEBUG};
}

=head2 warn

Outputs a warning message. This overrides the builtin perl warn() command.

=cut

sub warn {
	print STDERR "debconf: ".join(" ", @_)."\n";
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
