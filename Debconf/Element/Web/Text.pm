#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Web::Text - A paragraph on a form

=cut

package Debconf::Element::Web::Text;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This element handles a paragraph of text on a web form.

=head1 METHODS

=over 4

=item show

Generates and returns html for the paragraph of text.

=cut

sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	return "<b>".$this->question->description."</b>$_<p>";
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
