#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Line::Note - A note to the user

=cut

=head1 DESCRIPTION

This is a note to the user, presented using a plain text interface.

=cut

package Debian::DebConf::Element::Line::Note;
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
