#!/usr/bin/perl -w
#
# FrontEnd that presents a simple dialog interface, using whiptail (or dialog)
# This inherits from the generic ConfModule and just defines some methods to
# handle commands.

package FrontEnd::Dialog;
use FrontEnd::Base;
use Priority;
use strict;
use vars qw(@ISA);
@ISA=qw(FrontEnd::Base);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;
	
	# Autodetect if whiptail or dialog are available.
	if (-x "/usr/bin/whiptail") {
		$self->{program}='whiptail';
	}
	elsif (-x "/usr/bin/dialog") {
		$self->{program}='dialog';
	}
	else {
		die "Neither whiptail nor dialog is installed, so the dialog based frontend cannot be used.";
	}
	
	return $self;
}

# Shows a dialog. The first parameter is the dialog title (not to be
# confused with the frontend's main title). The remainder are passed to
# whiptail/dialog.
sub show_dialog {
	my $this=shift;
	my $title=shift;
	
	system $this->{program}, '--backtitle', $this->{title},
	       '--title', $title, @_;
}

1
