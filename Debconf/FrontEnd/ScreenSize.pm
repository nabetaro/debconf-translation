#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::ScreenSize - screen size tracker

=cut

package Debconf::FrontEnd::ScreenSize;
use strict;
use Debconf::Gettext;
use base qw(Debconf::FrontEnd);

=head1 DESCRIPTION

This FrontEnd is not useful standalone. It serves as a base for FrontEnds
that have a user interface that runs on a resizable tty. The screenheight
field is always set to the current height of the tty, while the screenwidth
field is always set to its width.

=over 4

=item screenheight

The height of the screen.

=item screenwidth

The width of the screen.

=item screenheight_guessed

Set to a true value if the screenheight was guessed to be 25, and may be
anything, if the screen has a height at all.

=back

=head1 METHODS

=over 4

=item init

Sets up SIGWINCH handler and gets current screen size.

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);

	$this->resize; # Get current screen size.
	$SIG{WINCH}=sub {
		# There is a short period during global destruction where
		# $this may have been destroyed but the handler still
		# operative.
		if (defined $this) {
			$this->resize;
		}
	};
}

=bitem resize

This method is called whenever the tty is resized, and probes to determine the
new screen size.

=cut

sub resize {
	my $this=shift;

	if (exists $ENV{LINES}) {
		$this->screenheight($ENV{'LINES'});
		$this->screenheight_guessed(0);
	}
	else {
		# Gotta be a better way..
		my ($rows)=`stty -a 2>/dev/null` =~ m/rows (\d+)/s;
		if ($rows) {
			$this->screenheight($rows);
			$this->screenheight_guessed(0);
		}
		else {
			$this->screenheight(25);
			$this->screenheight_guessed(1);
		}
	}

	if (exists $ENV{COLUMNS}) {
		$this->screenwidth($ENV{'COLUMNS'});
	}
	else {
		my ($cols)=`stty -a 2>/dev/null` =~ m/columns (\d+)/s;
		$this->screenwidth($cols || 80);
	}
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
