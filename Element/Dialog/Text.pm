#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Dialog::Text - A message in a dialog box

=cut

=head1 DESCRIPTION

This is an input element that can display a dialog box with a message on it.

=cut

package Debian::DebConf::Element::Dialog::Text;
use strict;
use Debian::DebConf::Element;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element);

sub show {
	my $this=shift;

	$this->frontend->showtext($this->question->description."\n\n".
		$this->question->extended_description
	);	
	$this->question->flag_isdefault('false');
}

1
