#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Web::Password - A password input field on a form

=cut

=head1 DESCRIPTION

This element handles a password input field on a web form.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Web::Password;
use strict;
use Debian::DebConf::Element::Base;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

=head2 show

Generates and returns html representing the password box.

=cut

sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	my $default=$this->question->value;
	my $id=$this->id;
	$_.="<b>".$this->question->description."</b><input type=password name=\"$id\" value=\"$default\">\n";

	return $_;
}

=head2 set

This gets called once the user has entered a value. It's passed the
value they entered. It saves the value in the associated Question.

=cut

sub set {
	my $this=shift;
	my $value=shift;

	$this->question->value($value);
	$this->question->flag_isdefault('false');
}

1
