#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Web::Text - A paragraph on a form

=cut

=head1 DESCRIPTION

This element handles a paragraph of text on a web form.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Web::Text;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

=head2 show

Generates and returns html for the paragraph of text.

=cut

sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	return "<b>".$this->question->description."</b>$_<p>";
}

1
