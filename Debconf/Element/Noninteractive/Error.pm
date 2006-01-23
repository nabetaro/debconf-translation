#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Noninteractive::Error - noninteractive error message Element

=cut

package Debconf::Element::Noninteractive::Error;
use strict;
use Text::Wrap;
use Debconf::Gettext;
use Debconf::Config;
use Debconf::Log ':all';
use base qw(Debconf::Element::Noninteractive::Note);

=head1 DESCRIPTION

This is a noninteractive error message Element. Since we are running
non-interactively, we can't pause to show the error messages. Instead, they
are mailed to someone.

=cut

=head1 METHODS

=over 4

=item show

Calls sendmail to mail the note, if the note has not been seen before.

=cut

sub show {
	my $this=shift;

	if ($this->question->flag('seen') ne 'true') {
		$this->sendmail(gettext("Debconf was not configured to display this error message, so it mailed it to you."));
	}
	$this->value('');
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>
Colin Watson <cjwatson@debian.org>

=cut

1
