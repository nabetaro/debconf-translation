#!/usr/bin/perl -w

=head1 NAME

DebConf::FrontEnd::Tty - Tty FrontEnd

=cut

=head1 DESCRIPTION

This FrontEnd is not useful by itself. It serves as a parent for any FrontEnds
that have a user interface that runs in a tty. The screenheight property of
this FrontEnd is always set to the current height of the tty, while the
screenwidth property is always set to its width.

=cut

=head1 METHODS

=cut

package Debian::DebConf::FrontEnd::Tty;
use strict;
use vars '@ISA';
use Debian::DebConf::FrontEnd; # perlbug
use base qw(Debian::DebConf::FrontEnd);

sub init {
	my $this=shift;

	$this->SUPER::init(@_);

	$this->resize; # Get current screen size.
	$SIG{'WINCH'}=sub { $this->resize };
}

=head2 resize

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

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
