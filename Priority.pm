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

{

	my $priority_level=$Debian::DebConf::Config::priority;

=head1 set

Set the current priority level to the specified value.

=cut

	sub set {
		my $new=shift;
		
		die "Unknown priority $new" unless exists $priorities{$new};
	
		$priority_level=$new;
	}

=head1 high_enough

Returns true iff the passed value is greater than or equal to
the current priority level.

=cut

	sub high_enough {
		my $priority=shift;
	
		die "Unknown priority $priority" unless exists $priorities{$priority};
	
		return $priorities{$priority} >= $priorities{$priority_level};
	}
}	

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
