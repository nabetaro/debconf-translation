#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang::Note - a note to show to the user

=cut

package Debian::DebConf::Element::Slang::Note;
use strict;
use Debian::DebConf::Gettext;
use Term::Stool::Button;
use Debian::DebConf::Element::Slang; # perlbug
use base qw(Debian::DebConf::Element::Slang
	    Debian::DebConf::Element::Noninteractive::Note);

=head1 DESCRIPTION

This is a note to show to the user. Notes have an associated button widget
that can be pressed to save the note.

=cut

sub init {
	my $this=shift;

	$this->widget(Term::Stool::Button->new(
		sameline => 1,
		text => gettext("Save Note"),
		preferred_width => 13,
		press_hook => sub {
			my $button=shift;
			if ($this->sendmail(gettext("Debconf was asked to save this note, so it mailed it to you."))) {
				$this->frontend->helpbar->push(gettext("The note has been mailed to root."));
			}
			else {
				$this->frontend->helpbar->push(gettext("Unable to save note."));
			}
			$this->frontend->helpbar->display;
			$button->display;
			$this->frontend->screen->refresh;
		},
	));
}

1
