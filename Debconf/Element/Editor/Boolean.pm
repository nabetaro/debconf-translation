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

=head1 METHODS

=over 4

=cut

sub show {
	my $this=shift;

	$this->frontend->comment($this->question->extended_description."\n\n".
		"(".gettext("Choices").": ".join(", ", gettext("yes"), gettext("no")).")\n".
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

=item value

Overridden to handle translating the value that the user typed in. Also,
if the user typed in something invalid, the value is not changed.

=cut

sub value {
	my $this=shift;
	
	return $this->SUPER::value() unless @_;
	my $value=shift;
	
	# Handle translated and non-translated replies.
	if ($value eq 'yes' || $value eq gettext("yes")) {
		return $this->SUPER::value('true');
	}
	elsif ($value eq 'no' || $value eq gettext("no")) {
		return $this->SUPER::value('false');
	}
	else {
		return $this->SUPER::value($this->question->value);
	}
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
