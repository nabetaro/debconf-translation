#!/usr/bin/perl -w
#
# This is a client module for ConfModules. It can communicate with the FrontEnd
# via the ConfModule protocol. The design is that each command in the protocol
# is represented by one function in this module (with the name lower-cased). 
# Call the function and pass in any parameters you want to follow the command.
# Any return code from the FrontEnd will be returned. You can use the Exporter
# to export any of the functions.

package ConfModule;
use strict;
use Exporter;
use vars qw($AUTOLOAD @ISA @EXPORT_OK);
@ISA = qw(Exporter);

# List all valid commands here.
@EXPORT_OK=qw(version capb stop reset title text input beginblock endblock go
		   note unset set get previous_module);

# Set up valid command lookup hash.
my %commands;
map { $commands{uc $_}=1; } @EXPORT_OK;

# Unbuffered output is required.
$|=1;

# Send in the current version unless overridden.
sub version {
	my $version=shift || '1.0';
	print "VERSION $version\n";
	my $ret=<STDIN>;
	chomp $ret;
	
	# TODO: check version?
	
	return $ret;
}

# Default command handler.
sub AUTOLOAD {
	my $command = uc $AUTOLOAD;
	$command =~ s|.*:||; # strip fully-qualified portion

	die "Unsupported command \"$command\"." unless $commands{$command};

	# It's really quite simple..
	print join (' ', $command, @_)."\n";
	my $ret=<STDIN>;
	chomp $ret;
	return $ret;
}
