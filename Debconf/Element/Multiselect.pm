#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Multiselect - Base multiselect input element

=cut

package Debconf::Element::Multiselect;
use strict;
use base qw(Debconf::Element::Select);

=head1 DESCRIPTION

This is a base Multiselect input element. It inherits from the base Select
input element.

=head1 METHODS

=item order_values

Given a set of values, reorders then to be in the same order as the choices
field of the question's template, and returns them.

=cut

sub order_values {
	my $this=shift;
	my %vals=map { $_ => 1 } @_;
	# Make sure that the choices are in the C locale, like the values
	# are.
	$this->question->template->i18n('');
	my @ret=grep { $vals{$_} } $this->question->choices_split;
	$this->question->template->i18n(1);
	return @ret;
}

=item show

Unlike select lists, multiselect questions are visible if there is just one
choice.

=cut

sub visible {
        my $this=shift;

        my @choices=$this->question->choices_split;
        return ($#choices >= 0);
}

=item translate_default

This method returns default value(s), in the user's language, suitable for
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
	
	my @ret;
	# Translate each default.
	foreach my $c_default ($this->question->value_split) {
		foreach (my $x=0; $x <= $#choices; $x++) {
			push @ret, $choices[$x]
				if $choices_c[$x] eq $c_default;
		}
	}
	return @ret;
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
