#!/usr/bin/perl -w
#
# Test framework for the Debian configuration management system.
# This can multiplex a variety of frontends, just pass the name of
# the frontend as the first parameter. Pass in the name of the templates
# file and then the mapping file and finally the config script.

use strict;
use Debian::DebConf::ConfigDb;
use Debian::DebConf::FrontEnd::Line;
use Debian::DebConf::FrontEnd::Dialog;
use Debian::DebConf::FrontEnd::Web;
use Debian::DebConf::ConfModule::Dialog;
use Debian::DebConf::ConfModule::Line;
use Debian::DebConf::ConfModule::Web;
use Debian::DebConf::Priority;

my $type=shift;
my $template=shift;
my $mapping=shift;
my $script=shift;

# Load up previous state information.
if (-e 'debconf.db') {
	Debian::DebConf::ConfigDb::loaddb('debconf.db');
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

# Start up the FrontEnd and ConfModule.
my $frontend=eval "Debian::DebConf::FrontEnd::$type->new()";
die $@ if $@;
my $confmodule=eval 'Debian::DebConf::ConfModule::'.$type.'->new($script, $frontend)';
die $@ if $@;

# Talk to it until it is done.
1 while ($confmodule->communicate);

# Save state.
Debian::DebConf::ConfigDb::savedb('debconf.db');
