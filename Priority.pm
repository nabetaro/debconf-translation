#!/usr/bin/perl -w
#
# This module deals with question priority levels.

package Debian::DebConf::Priority;
use strict;

my %priorities=(
	'low' => 0,
	'medium' => 1,
	'high' => 2,
	'critical' => 3,
);

{

	my $priority_level='medium';

	# Set the priority level.
	sub set {
		my $new=shift;
		
		die "Unknown priority $new" unless exists $priorities{$new};
	
		$priority_level=$new;
	}

	# Returns true if the passed priority is high enough to be displayed under
	# the current priority level.
	sub high_enough {
		my $priority=shift;
	
		die "Unknown priority $priority" unless exists $priorities{$priority};
	
		return $priorities{$priority} >= $priorities{$priority_level};
	}
}	

1

