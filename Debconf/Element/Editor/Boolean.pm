#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Editor::Boolean - Yes/No question

=cut

package Debconf::Element::Editor::Boolean;
use strict;
use Debconf::Gettext;
use base qw(Debconf::Element);

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
		$default=gettext("yes");
	}
	elsif ($default eq 'false') {
		$default=gettext("no");
	}

	$this->frontend->item($this->question->name, $default);
}

=item process

Validates the input. If it's not valid, returns the old default.

=cut

sub process {
	my $this=shift;
	my $value=shift;
	
	# Handle translated and non-translated replies.
	return 'true' if $value eq 'yes' || $value eq gettext("yes");
	return 'false' if $value eq 'no' || $value eq gettext("no");
	return $this->question->value;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
