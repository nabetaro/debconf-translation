#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang::String - text input widget

=cut
                
=head1 DESCRIPTION

This is a text input widget.

=cut

package Debian::DebConf::Element::Slang::String;
use strict;
use Term::Stool::Input;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

sub makewidget {
	my $this=shift;

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	$this->widget(Term::Stool::Input->new(@_, text => $default));
}

sub value {
	my $this=shift;

	return $this->widget->text;
}

1
