#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Tty - Tty FrontEnd

=cut

package Debconf::FrontEnd::Tty;
use strict;
use vars '@ISA';
use Debconf::FrontEnd; # perlbug
use base qw(Debconf::FrontEnd);

=head1 DESCRIPTION

This FrontEnd is not useful by itself. It serves as a parent for any FrontEnds
that have a user interface that runs in a tty. The screenheight field is
always set to the current height of the tty, while the screenwidth field is
always set to its width.

=head1 METHODS

=over 4

=item init

Sets up SIGWINCH handler and gets current screen size.

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);

	$this->resize; # Get current screen size.
	$SIG{'WINCH'}=sub { $this->resize };
}

=item resize

This method is called whenever the tty is resized, and probes to determine the
new screen size.

=cut

sub resize {
	my $this=shift;

	if (exists $ENV{'LINES'}) {
		$this->screenheight($ENV{'LINES'});
	}
	else {
		# Gotta be a better way..
		my ($rows)=`stty -a </dev/tty` =~ m/rows (\d+)/s;
		$this->screenheight($rows || 25);
	}

	if (exists $ENV{'COLUMNS'}) {
		$this->screenwidth($ENV{'COLUMNS'});
	}
	else {
		my ($cols)=`stty -a </dev/tty` =~ m/columns (\d+)/s;
		$this->screenwidth($cols || 80);
	}
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
