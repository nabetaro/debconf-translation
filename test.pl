#!/usr/bin/perl -w
#
# Test framework for the Debian configuration management system.
# This can multiplex a variety of frontends, just pass the name of
# the frontend as the first parameter. Pass in the name of the templates
# file and then the mapping file and finally the config script.

use strict;
use lib '.';
use Debian::DebConf::ConfigDb;
use Debian::DebConf::Priority;
use Debian::DebConf::Config;

my $type=shift;
my $template=shift;
my $mapping=shift;
my $script=shift;

# Load up previous state information.
if (-e $Debian::DebConf::Config::dbfn) {
	Debian::DebConf::ConfigDb::loaddb($Debian::DebConf::Config::dbfn);
}

# Load up templates.
Debian::DebConf::ConfigDb::loadtemplatefile($template);

# Load up mappings.
Debian::DebConf::ConfigDb::loadmappingfile($mapping);

# Instantiate all questions that have mappings.
Debian::DebConf::ConfigDb::makequestions();

# Set priority.
if (exists $ENV{PRIORITY}) {
	Debian::DebConf::Priority::set($ENV{PRIORITY});
}

# Load modules and start up the FrontEnd and ConfModule.
my $frontend=eval qq{
	use Debian::DebConf::FrontEnd::$type;
	Debian::DebConf::FrontEnd::$type->new();
};
die $@ if $@;
my $confmodule=eval qq{
	use Debian::DebConf::ConfModule::$type;
	Debian::DebConf::ConfModule::$type->new(\$frontend, \$script);
};
die $@ if $@;

# Talk to it until it is done.
1 while ($confmodule->communicate);

# Save state.
Debian::DebConf::ConfigDb::savedb($Debian::DebConf::Config::dbfn);
