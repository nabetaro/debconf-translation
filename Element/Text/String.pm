#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Text::String - password input field

=cut
                
=head1 DESCRIPTION

This is a string input field, presented to the user using a plain text
interface.

=cut

package Debian::DebConf::Element::Text::String;
use strict;
use Debian::DebConf::Element;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element);

sub show {
	my $this=shift;

	# Display the question's long desc first.
	$this->frontend->display(
		$this->question->extended_description."\n");
	
	my $default=$this->question->value;
	
	# Prompt for input using the short description.
	$_=$this->frontend->prompt($this->question->description." ", $default);
	
	# Handle defaults.
	if ($_ eq '' && defined $default) {
		$_=$default;
	}

	$this->question->value($_);
	$this->question->flag_isdefault('false');
	
	$this->frontend->display("\n");
}

1
