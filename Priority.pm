#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Priority - priority level module

=cut

=head1 DESCRIPTION

This is a simple perl module, not an object. It is used to deal with
the priorities of Questions.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Priority;
use strict;
use Debian::DebConf::Config;

=head1

Currently known priorities are low, medium, high, and critical.

=cut

my %priorities=(
	'low' => 0,
	'medium' => 1,
	'high' => 2,
	'critical' => 3,
);

=head1 METHODS

=cut

=head1 high_enough

Returns true iff the passed value is greater than or equal to the current
priority level. Note that if an inknown pririty is passed in, it is assumed
to be higher.

=cut

sub high_enough {
	my $priority=shift;

	return 1 if ! exists $priorities{$priority};
	return $priorities{$priority} >= $priorities{Debian::DebConf::Config::priority()};
}

=head1 valid

Returns true if the passed text is a valid priority.

=cut

sub valid {
	my $priority=shift;

	return exists $priorities{$priority};
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
