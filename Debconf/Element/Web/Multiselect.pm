#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Web::Multiselect - A multi select box on a form

=cut

package Debconf::Element::Web::Multiselect;
use strict;
use Debconf::Element::Multiselect; # perlbug
use base qw(Debconf::Element::Multiselect);

=head1 DESCRIPTION

This element handles a multi select box on a web form.

=head1 METHODS

=over 4

=item show

Generates and returns html representing the multi select box.

=cut

sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	my %value = map { $_ => 1 } $this->translate_default;

	my $id=$this->id;
	$_.="<b>".$this->question->description."</b>\n<select multiple name=\"$id\">\n";
	my $c=0;
	foreach my $x ($this->question->choices_split) {
		if (! $value{$x}) {
			$_.="<option value=".$c++.">$x\n";
		}
		else {
			$_.="<option value=".$c++." selected>$x\n";
		}
	}
	$_.="</select>\n";
	
	return $_;
}

=item process

This gets called once the user has entered a value. It expects to be passed
all the values they selected. It processes these into the form used internally
and returns that.

=cut

sub process {
	my $this=shift;
	# This forces the function that provides values to this method
	# to be called in scalar context, so we are passed a list of
	# the selected values.
	my @values=@_;

	# Get the choices in the C locale.
	$this->question->template->i18n('');
	my @choices=$this->question->choices_split;
	$this->question->template->i18n(1);
	
	return join(', ',  map { $choices[$_] } @values);
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1