#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Line::Text - show text to the user

=cut

=head1 DESCRIPTION

This is a peice of text to output to the user.

=cut

package Debian::DebConf::Element::Line::Text;
use strict;
use Debian::DebConf::Element::Base;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

sub show {
	my $this=shift;

	$this->frontend->display($this->question->description."\n".
		$this->question->extended_description."\n");

	$this->question->flag_isdefault('false');
}

1
