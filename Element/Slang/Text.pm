#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang::Text - a bit of text to show to the user.

=cut

package Debian::DebConf::Element::Slang::Text;
use strict;
use Term::Stool::Widget;
use Debian::DebConf::Element::Slang; # perlbug
use base qw(Debian::DebConf::Element::Slang);

=head1 DESCRIPTION

This is a bit of text to show to the user.

=cut

sub init {
	my $this=shift;
	
	# Make a widget only because the frontend expects us to. The widget
	# is not displayed or used at all.
	$this->widget(Term::Stool::Widget->new(
		can_focus => 0,
		sameline => 1,
		width => 1,
		preferred_width => 0,
	));
}

1
