#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Web::Select - A select box on a form

=cut

package Debconf::Element::Web::Select;
use strict;
use base qw(Debconf::Element::Select);

=head1 DESCRIPTION

This element handles a select box on a web form.

=head1 METHODS

=over 4

=item show

Generates and returns html representing the select box.

=cut

sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	my $default=$this->translate_default;
	my $id=$this->id;
	$_.="<b>".$this->question->description."</b>\n<select name=\"$id\">\n";
	my $c=0;
	foreach my $x ($this->question->choices_split) {
		if ($x ne $default) {
			$_.="<option value=".$c++.">$x\n";
		}
		else {
			$_.="<option value=".$c++." selected>$x\n";
		}
	}
	$_.="</select>\n";
	
	return $_;
}

=item value

Overridden to handle translating the value back to C locale when it is set.

=cut

sub value {
	my $this=shift;

	return $this->SUPER::value() unless @_;
	my $value=shift;

	# Get the choices in the C locale.
	$this->question->template->i18n('');
	my @choices=$this->question->choices_split;
	$this->question->template->i18n(1);
	$this->SUPER::value($choices[$value]);
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
