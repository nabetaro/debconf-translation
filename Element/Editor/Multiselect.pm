#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Editor::MultiSelect - select from a list of choices

=cut

package Debian::DebConf::Element::Editor::Multiselect;
use strict;
use Debian::DebConf::Gettext;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

Presents a list of choices to be selected amoung. Multiple selection is
allowed.

=head1 METHODS

=over 4

=cut

sub show {
	my $this=shift;

	my @choices=$this->question->choices_split;

	$this->frontend->comment($this->question->extended_description."\n\n".
		"(".gettext("Choices").": ".join(", ", @choices).")\n".
		gettext("(Enter zero or more items separated by spaces.)")."\n".
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

Convert from a space-separated list into the internal format. At the same
time, validate each item and make sure it is allowable, or remove it.

=cut

sub process {
	my $this=shift;
	my @values=split(' ', shift);
	my %valid=map { $_ => 1 } $this->question->choices_split;
	
	return join(', ', grep { $valid{$_} } @values);
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
