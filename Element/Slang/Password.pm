#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang::Password - passowrd input widget

=cut
                
=head1 DESCRIPTION

This is a password input widget.

=cut

package Debian::DebConf::Element::Slang::Password;
use strict;
use Term::Stool::Password;
use Debian::DebConf::Element::Slang; # perlbug
use base qw(Debian::DebConf::Element::Slang);

sub init {
	my $this=shift;

	$this->widget(Term::Stool::Password->new);
	$this->widget->preferred_width($this->widget->width);
}

=head2 value

If the widget's value field is empty, return the default.

=cut

sub value {
	my $this=shift;
	
	my $text=$this->widget->text;
	$text=$this->question->value if $text eq '';
	return $text;
}

1
