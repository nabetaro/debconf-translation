#!/usr/bin/perl -w

=head1 NAME

Debconf::Priority - priority level module

=cut

package Debconf::Priority;
use strict;
use Debconf::Config qw(priority);
use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(high_enough priority_valid);

=head1 DESCRIPTION

This module deals with the priorities of Questions.

Currently known priorities are low, medium, high, and critical.

=cut

my %priorities=(
	'low' => 0,
	'medium' => 1,
	'high' => 2,
	'critical' => 3,
);

=head1 METHODS

=over 4

=item high_enough

Returns true iff the passed value is greater than or equal to the current
priority level. Note that if an unknown priority is passed in, it is assumed
to be higher.

=cut

sub high_enough {
	my $priority=shift;

	return 1 if ! exists $priorities{$priority};
	return $priorities{$priority} >= $priorities{priority()};
}

=item priority_valid

Returns true if the passed text is a valid priority.

=cut

sub priority_valid {
	my $priority=shift;

	return exists $priorities{$priority};
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
