#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Web::Boolean - A check box on a form

=cut

=head1 DESCRIPTION

This element handles a check box on a web form.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Web::Boolean;
use strict;
use Debian::DebConf::Element;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element);

=head2 show

Generates and returns html representing the check box.

=cut

sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	my $type=$this->question->type;
	my $default=$this->question->value;
	my $id=$this->id;
	$_.="<input type=checkbox name=\"$id\"". ($default eq 'true' ? ' checked' : ''). ">\n<b>".
		$this->question->description."</b>";

	return $_;
}

=head2 set

This gets called once the user has entered a value. It's passed the
value they entered. It saves the value in the associated Question.

=cut

sub set {
	my $this=shift;
	my $value=shift;

	$this->question->value($value eq 'on' ? 'true' : 'false');
	$this->question->flag_isdefault('false');
}

1
