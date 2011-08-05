#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Noninteractive - non-interactive FrontEnd

=cut

package Debconf::FrontEnd::Noninteractive;
use strict;
use Debconf::Encoding qw(width wrap);
use Debconf::Gettext;
use base qw(Debconf::FrontEnd);

=head1 DESCRIPTION

This FrontEnd is completly non-interactive.

=cut

=item init

tty not needed

=cut

sub init { 
        my $this=shift;

        $this->SUPER::init(@_);

        $this->need_tty(0);
}

=item display

Displays text wrapped to fit on the screen. If a title has been set and has
not yet been displayed, displays it first.

=cut

sub display {
	my $this=shift;
	my $text=shift;

	# Hardcode the width because we might not have any console
	$Debconf::Encoding::columns=76;
	$this->display_nowrap(wrap('','',$text));
}

=item display_nowrap

Displays text.  If a title has been set and has not yet been displayed,
displays it first.

=cut

sub display_nowrap {
	my $this=shift;
	my $text=shift;

	# Silly split elides trailing null matches.
	my @lines=split(/\n/, $text);
	push @lines, "" if $text=~/\n$/;

	# Add to the display any pending title.
	my $title=$this->title;
	if (length $title) {
		unshift @lines, $title, ('-' x width $title), '';
		$this->title('');
	}

	foreach (@lines) {
		print "$_\n";
	}
}

1
