#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Dialog::Text - A message in a dialog box

=cut

package Debian::DebConf::Element::Dialog::Text;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

This is an input element that can display a dialog box with a message on it.

=cut

sub show {
	my $this=shift;

	$this->frontend->showtext($this->question->description."\n\n".
		$this->question->extended_description
	);	
	return '';
}

1
