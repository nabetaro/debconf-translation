#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Editor::Select - select from a list of choices

=cut

package Debian::DebConf::Element::Editor::Select;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

Presents a list of choices to be selected amoung.

=head2 METHODS

=over 4

=cut

sub show {
	my $this=shift;

	my @choices=$this->question->choices_split;

	$this->frontend->comment($this->question->extended_description."\n\n".
		"(Choices: ".join(", ", @choices).")\n".
		$this->question->description."\n");

	my $default='';
	$default=$this->question->value if defined $this->question->value;

	# Make sure the default is in the set of choices, else ignore it.
	if (! grep { $_ eq $default } @choices) {
		$default='';
	}

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
	
	return $value if $valid{$value};
	return $this->question->value;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
