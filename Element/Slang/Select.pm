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
use base qw(Debian::DebConf::Element::Select);

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
	# The widget prefers to be just wide enough for the list box,
	# plus one character. The one character makes it look better, IMHO.
	$this->widget->preferred_width($this->widget->list->width + 5);
}

=head2 resize

This is called when the widget is resized.

Try to make the widget as wide as its preferred_width attrribute. If there's
room for a widget that wide to fix on the same line as the description, do so.
Otherwise, put the widget on the next line.

=cut

sub resize {
	my $this=shift;
	my $widget=$this->widget;
	my $description=$widget->description;
	my $maxwidth=$widget->container->width - 4;

	if ($maxwidth > $widget->preferred_width + $description->width) {
		$widget->sameline(1);
		$widget->width($widget->preferred_width);
		$widget->xoffset($description->width + 2);
	}
	elsif ($maxwidth > $widget->preferred_width) {
		$widget->sameline(0);
		$widget->width($widget->preferred_width);
		$widget->xoffset(1);
	}
	else {
		$widget->sameline(0);
		$widget->width($maxwidth);
		$widget->xoffset(1);
	}
}

sub value {
	my $this=shift;

	return $this->widget->list->value;
}

1
