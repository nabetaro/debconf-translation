#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang::Select - drop down select box widget

=cut
                
=head1 DESCRIPTION

This is a drop down select box widget.

=cut

package Debian::DebConf::Element::Slang::Select;
use strict;
use Term::Stool::DropDown;
use Debian::DebConf::Element::Select; # perlbug
use base qw(Debian::DebConf::Element::Select
	    Debian::DebConf::Element::Slang::String);

sub makewidget {
	my $this=shift;

	my @choices=$this->question->choices_split;
	my $default='';
	$default=$this->question->value if defined $this->question->value;

	# Find cursor position.
	my $cursor=1;
	for (my $x=0; $x < $#choices ; $x++) {
		if ($choices[$x] eq $default) {
			$cursor=$x;
			last;
		}
	}	

	$this->widget(Term::Stool::DropDown->new(
		list => Term::Stool::List->new(
			contents => [@choices],
			cursor => $cursor,
		),
	));
	# The widget prefers to be just wide enough for the list box.
	$this->widget->preferred_width($this->widget->list->width + 4);
}

sub value {
	my $this=shift;

	return $this->widget->list->value;
}

1
