#!/usr/bin/perl -w
#
# Test frontend for the Debian configuration management system.

use strict;
use ConfigDb;
use FrontEnd::Line;

# Load up templates.
ConfigDb::loadtemplatefile(shift);

# Instantiate all questions.
ConfigDb::makequestions();

# Start up the confmodule.
my $frontend=FrontEnd::Line->new(shift);

# Talk to it until it is done.
1 while ($frontend->communicate);
