#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Web::Boolean - A check box on a form

=cut

package Debconf::Element::Web::Boolean;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This element handles a check box on a web form.

=head1 METHODS

=over 4

=item show

Generates and returns html representing the check box.

=cut

sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	my $id=$this->id;
	$_.="<input type=checkbox name=\"$id\"". ($default eq 'true' ? ' checked' : ''). ">\n<b>".
		$this->question->description."</b>";

	return $_;
}

=item process

This gets called once the user has entered a value, to process it before
it is stored.

=cut

sub process {
	my $this=shift;
	my $value=shift;

	return $value eq 'on' ? 'true' : 'false';
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
