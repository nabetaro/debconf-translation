#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Web::String - A text input field on a form

=cut

package Debconf::Element::Web::String;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This element handles a text input field on a web form.

=head1 METHODS

=over 4

=item show

Generates and returns html representing the text box.

=cut

sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	my $id=$this->id;
	$_.="<b>".$this->question->description."</b><input name=\"$id\" value=\"$default\">\n";

	return $_;
}

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
