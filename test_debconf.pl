#!/usr/bin/perl -w -I.

sub usage {
	print STDERR <<EOF;
Usage: 
    test_debconf.pl OneTest
    test_debconf.pl --all
EOF
	exit(1);
}

use strict;
use Test::Unit::TestRunner;
use Getopt::Long;

my $all=0;
my $test=0;

# command options
GetOptions(
	"all" => \$all,
) || usage();

unless ($all) {
	$test=$ARGV[0];
	usage() unless $test;
}

if ($test) {
	Test::Unit::TestRunner->main($test);
}
if ($all) {
	Test::Unit::TestRunner->main("Test::AllTests");
}
