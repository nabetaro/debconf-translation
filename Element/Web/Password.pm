#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Web::Password - A password input field on a form

=cut

package Debian::DebConf::Element::Web::Password;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

This element handles a password input field on a web form.

=head1 METHODS

=over 4

=item show

Generates and returns html representing the password box.

=cut

sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	my $id=$this->id;
	$_.="<b>".$this->question->description."</b><input type=password name=\"$id\" value=\"$default\">\n";

	return $_;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
