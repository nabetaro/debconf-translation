#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Editor::Select - select from a list of choices

=cut

package Debconf::Element::Editor::Select;
use strict;
use Debconf::Gettext;
use base qw(Debconf::Element::Select);

=head1 DESCRIPTION

Presents a list of choices to be selected amoung.

=head2 METHODS

=over 4

=cut

sub show {
	my $this=shift;

	my $default=$this->translate_default;
	my @choices=$this->question->choices_split;

	$this->frontend->comment($this->question->extended_description."\n\n".
		"(".gettext("Choices").": ".join(", ", @choices).")\n".
		$this->question->description."\n");
	$this->frontend->item($this->question->name, $default);
}

=item process

Verifies that the value is one of the choices. If not, or if the value
isn't set, return whatever the old value of the Question was.

=cut

sub process {
	my $this=shift;
	my $value=shift;
	my %valid=map { $_ => 1 } $this->question->choices_split;
	
	return $this->translate_to_C($value) if $valid{$value};
	return $this->question->value;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
