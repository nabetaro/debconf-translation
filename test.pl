#!/usr/bin/perl -w
#
# Test framework for the Debian configuration management system.
# This can multiplex a variety of frontends, just pass the name of
# the frontend as the first parameter. Pass in the name of the templates
# file and then the mapping file and finally the config script.

use strict;
use ConfigDb;
use FrontEnd::Line;
use FrontEnd::Dialog;
use FrontEnd::Web;
use ConfModule::Dialog;
use ConfModule::Line;
use ConfModule::Web;

my $type=shift;
my $template=shift;
my $mapping=shift;
my $script=shift;

# Load up templates.
ConfigDb::loadtemplatefile($template);

# Load up mappings.
ConfigDb::loadmappingfile($mapping);

# Instantiate all questions that have mappings.
ConfigDb::makequestions();

# Start up the FrontEnd and ConfModule.
my $frontend=eval "FrontEnd::$type->new()";
die $@ if $@;
my $confmodule=eval 'ConfModule::'.$type.'->new($script, $frontend)';
die $@ if $@;

# Talk to it until it is done.
1 while ($confmodule->communicate);
