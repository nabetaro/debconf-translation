#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Editor::Boolean - Yes/No question

=cut

package Debian::DebConf::Element::Editor::Boolean;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

This is a yes or no question.

=cut

sub show {
	my $this=shift;

	$this->frontend->comment($this->question->extended_description."\n\n".
		$this->question->description."\n");

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	if ($default eq 'true') {
		$default='yes';
	}
	elsif ($default eq 'false') {
		$default='no';
	}

	$this->frontend->item($this->question->name, $default);
}

=item process

Validates the input. If it's not valid, returns the old default.

=cut

sub process {
	my $this=shift;
	my $value=shift;
	
	return 'true' if $value eq 'yes';
	return 'false' if $value eq 'no';
	return $this->question->value;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
