#!/usr/bin/perl

=head1 NAME

Debconf::Log - debconf log module

=cut

package Debconf::Log;
use strict;
use base qw(Exporter);
our @EXPORT_OK=qw(debug warn);
# Import :all to get everything.
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

=head1 DESCRIPTION

This is a log module for debconf.

This module uses Exporter.

=head1 METHODS

=over 4

=item debug

Outputs an infomational message. The first parameter specifies the type of
information that is being logged. If DEBCONF_DEBUG is set in the
environment to something that matches the parameter, the message is output.

Note that DEBCONF_DEBUG can be set to a regular expression, like '.*'.

Currently used types of information: user, developer, debug

=cut

sub debug {
	my $type=shift;
	if (exists $ENV{DEBCONF_DEBUG} && $type =~ /$ENV{DEBCONF_DEBUG}/) {
		print STDERR "debconf ($type): ".join(" ", @_)."\n";
	}
}

=item warn

Outputs a warning message. This overrides the builtin perl warn() command.

=cut

sub warn {
	print STDERR "debconf: ".join(" ", @_)."\n";
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
