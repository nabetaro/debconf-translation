#!/usr/bin/perl -w
#
# This module deals with question priority levels.

package Priority;
use strict;

my %priorities=(
	'low' => 0,
	'medium' => 1,
	'high' => 2,
	'critical' => 3,
);

# Returns true if the passed priority is high enough to be displayed under
# the current priority level.
sub high_enough {
	my $priority=shift;
	
	my $current=($ENV{DEBIAN_PRIORITY} || 'medium');
	
	return $priorities{$priority} >= $priorities{$current};
}

1
