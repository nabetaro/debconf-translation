#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Select - Base select input element

=cut

package Debian::DebConf::Element::Select;
use strict;
use Debian::DebConf::Gettext;
use Debian::DebConf::Log ':all';
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

This is a base Select input element.

=head1 METHODS

=over 4

=item show

Select elements are not really visible if there are less than two choices
for them.

=cut

sub visible {
	my $this=shift;
	
	my @choices=$this->question->choices_split;
	return ($#choices > 0);
}

=item translate_default

This method returns a default value, in the user's language, suitable for
displaying to the user. Defaults are stored internally in the C locale;
this method does any necessary translation to the current locale.

=cut

sub translate_default {
	my $this=shift;

	# I need both the translated and the non-translated choices.
	my @choices=$this->question->choices_split;
	$this->question->template->i18n('');
	my @choices_c=$this->question->choices_split;
	$this->question->template->i18n(1);

	# Get the C default.
	my $c_default='';
	$c_default=$this->question->value if defined $this->question->value;
	# Translate it.
	foreach (my $x=0; $x <= $#choices; $x++) {
		return $choices[$x] if $choices_c[$x] eq $c_default;
	}
	# If it's not in the list of choices, just ignore it.
	return '';
}

=item translate_to_C

Pass a value in the current locale in to this function, and it will look it
up in the list of choices, convert it back to the C locale, and return it.

=cut

sub translate_to_C {
	my $this=shift;
	my $value=shift;

	# I need both the translated and the non-translated choices.
	my @choices=$this->question->choices_split;
	$this->question->template->i18n('');
	my @choices_c=$this->question->choices_split;
	$this->question->template->i18n(1);
	
	for (my $x=0; $x <= $#choices; $x++) {
		return $choices_c[$x] if $choices[$x] eq $value;
	}
	debug developer => sprintf(gettext("Input value, \"%s\" not found in C choices! This should never happen. Perhaps the templates were incorrectly localized."), $value);
	return '';
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
