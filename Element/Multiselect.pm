#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Multiselect - Base multiselect input element

=cut

package Debian::DebConf::Element::Multiselect;
use strict;
use Debian::DebConf::Element::Select; # perlbug
use base qw(Debian::DebConf::Element::Select);

=head1 DESCRIPTION

This is a base Multiselect input element. It inherits from the base Select
input element.

=head1 METHODS

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

Joey Hess <joey@kitenet.net>

=cut

1
