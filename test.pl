#!/usr/bin/perl -w
#
# Test framework for the Debian configuration management system.
# This can multiplex a variety of frontends, just pass the name of
# the frontend as the first parameter. Pass in the name of the templates
# file and the config script.

use strict;
use lib '.';
use Debian::DebConf::ConfigDb;
use Debian::DebConf::Config;
use Debian::DebConf::AutoSelect;

Debian::DebConf::Config::frontend(shift);
my $template=shift;
my $script=shift;

# Load up previous state information.
if (-e Debian::DebConf::Config::dbfn()) {
	Debian::DebConf::ConfigDb::loaddb(Debian::DebConf::Config::dbfn());
}

# Load up templates.
Debian::DebConf::ConfigDb::loadtemplatefile($template, $script);

# Set priority.
if (exists $ENV{PRIORITY}) {
	Debian::DebConf::Config::priority($ENV{PRIORITY});
}

my $frontend=Debian::DebConf::AutoSelect::frontend();
my $confmodule=Debian::DebConf::AutoSelect::confmodule($script);

# Make sure any questions that are created are owned by this script.
$confmodule->owner($script);

# Talk to it until it is done.
1 while ($confmodule->communicate);

# Save state.
Debian::DebConf::ConfigDb::savedb(Debian::DebConf::Config::dbfn());
