#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang::Note - a note to show to the user

=cut
                
=head1 DESCRIPTION

This is a note to show to the user.

=cut

package Debian::DebConf::Element::Slang::Note;
use strict;
use Term::Stool::Text;
use Debian::DebConf::Element::Slang; # perlbug
use base qw(Debian::DebConf::Element::Slang);

sub init {
	my $this=shift;

	# The widget can be focused, but that's about it..
	$this->widget(Term::Stool::Text->new(
		sameline => 1,
		can_focus => 1,
		xoffset => 1,
		text => ' ',
		preferred_width => 0,
	));
}

1
