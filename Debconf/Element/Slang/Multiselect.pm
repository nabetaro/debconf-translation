#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Slang::Multiselect - multiselect "widget"

=cut

package Debconf::Element::Slang::Multiselect;
use strict;
use Term::Stool::CheckBox;
use Term::Stool::Text;
use base qw(Debconf::Element::Multiselect Debconf::Element::Slang);

=head1 DESCRIPTION

Since I cannot think of a usable drop down multiselect widget, I have just
made this use an array of checkboxes.

=cut

=head1 METHODS

=over 4

=cut

sub make_widgets {
	my $this=shift;

	my %default=map { $_ => 1 } $this->translate_default;
	my @choices=$this->question->choices_split;
	
	# Add all the checkboxes and labels to the widget list.
	my @widgets;
	foreach my $choice (@choices) {
		push @widgets, Term::Stool::CheckBox->new(
			checked => ($default{$choice} ? 1 : 0)
		);
		push @widgets, Term::Stool::Text->new(text => $choice);
	}

	return @widgets;
}

=item resize

The widget description goes on its own line. Following it, indented,
are the checkboxes, with the labels on the same line after them.

=cut

sub resize {
	my $this=shift;
	my $y=shift;

	my $description=$this->widget_description;
	my $maxwidth=$description->container->width - 4;

	$description->yoffset($y);
	$y++;

	my @widgets=@{$this->widgets};
	for (my $i=0; $i<@widgets; $i+=2) {
		my ($widget, $label)=@widgets[$i, $i+1];
		$widget->xoffset(2);
		$widget->yoffset($y);
		$label->xoffset(3 + $widget->width);
		$label->yoffset($y);
		$label->width($maxwidth - 3 - $widget->width);
		$y++;
	}

	return $y;
}

=item value

To calculate the value, we must gather the state of each check box, and
then translate its label back to the C locale.

=cut

sub value {
	my $this=shift;

	my @values=();
	my @widgets=@{$this->widgets};
	for (my $i=0; $i<@widgets; $i+=2) {
		my ($widget, $label)=@widgets[$i, $i+1];
		if ($widget->checked) {
			push @values, $this->translate_to_C($label->text);
		}
	}

	return join(", ", @values);
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
