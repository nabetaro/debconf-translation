#!/usr/bin/perl -w

=head1 NAME

   DebConf::Client::ConfModule - client module for ConfModules

=cut

=head1 SYNOPSIS

	use Debian::DebConf::Client::ConfModule ':all';
	version;
	my $capb=capb('backup');
	input("foo/bar");
	go;

=cut

=head1 DESCRIPTION

This is a module to ease writing ConfModules for Debian's configuration
management system. It can communicate with a FrontEnd via the ConfModule
protocol. The design is that each command in the protocol is represented by
one function in this module (with the name lower-cased). Call the function and
pass in any parameters you want to follow the command. Any return code from the
FrontEnd will be returned to you.

This module uses Exporter to export all functions it defines. To import
everything, simply import ":all".

A few functions have special features, as documented below:

=cut

package Debian::DebConf::Client::ConfModule;
use strict;
use lib '.';
use Exporter;
use vars qw($AUTOLOAD @ISA @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

# List all valid commands here.
@EXPORT_OK=qw(version capb stop reset title input beginblock endblock go
	      unset set get register unregister previous_module
	      start_frontend fset fget);

# Import :all to get everything.		   
%EXPORT_TAGS = (all => [@EXPORT_OK]);

# Set up valid command lookup hash.
my %commands;
map { $commands{uc $_}=1; } @EXPORT_OK;

# Unbuffered output is required.
$|=1;

=head2 import

Ensure that a FrontEnd is running.  It's a little hackish. If
DEBIAN_HAS_FRONTEND is set, a FrontEnd is assumed to be running.
If not, one is started up automatically and stdin and out are
connected to it. A name of a FrontEnd to start can be passed in
DEBIAN_FRONTEND, it defaults to using the base (non-interactive)
FrontEnd. Note that this function is always run when the module is
loaded in the usual way.

=cut

sub import {
	my $type=ucfirst($ENV{DEBIAN_FRONTEND} || 'base' );

	# Ensure a frontend is running. If not, turn into one and fork off
	# a child to continue.
	unless ($ENV{DEBIAN_HAS_FRONTEND}) {
		my $frontend=eval qq{
			use Debian::DebConf::FrontEnd::$type;
			Debian::DebConf::FrontEnd::$type->new();
		};
		die $@ if $@;
		my $confmodule=eval qq{
			use Debian::DebConf::ConfModule::$type;
			Debian::DebConf::ConfModule::$type->new(\$frontend);
		};
		die $@ if $@;
		
		# Set up the pipes the two processes will use to communicate.
		pipe($confmodule->read_handle(FileHandle->new), \*CHILD_STDOUT);
		pipe(\*CHILD_STDIN, $confmodule->write_handle(FileHandle->new));
		
		# Prevent deadlocks.
		autoflush CHILD_STDOUT 1;
		$confmodule->write_handle->autoflush;
		
		if ($confmodule->pid(fork)) {
			# Parent process. This is the FrontEnd now.
			# More modules a FrontEnd needs.
			eval q{
				use Debian::DebConf::ConfigDb;
				use Debian::DebConf::Config;
			};
			die $@ if $@;
			
			# Load up previous state information.
			if (-e $Debian::DebConf::Config::dbfn) {
				Debian::DebConf::ConfigDb::loaddb($Debian::DebConf::Config::dbfn);
			}
			
			# Talk to my child until it is done. Reading from the child actually
			# blocks when the child exits, so to tell if it's done, I'll use a
			# SIGCHLD handler.
			$SIG{CHLD}=sub {
				# Save state.
				Debian::DebConf::ConfigDb::savedb($Debian::DebConf::Config::dbfn);
				exit;
			};
			1 while ($confmodule->communicate);
		}
		
		# Child process. Continue on as before. First, set STDIN and
		# OUT to communicate with our parent.
		*STDIN=\*CHILD_STDIN;
		*STDOUT=\*CHILD_STDOUT;
	}

	# Make the Exporter still work.
	Debian::DebConf::Client::ConfModule->export_to_level(1, @_);
}

=head2 version

By default, the current protocol version is sent to the frontend. You can pass
in a different version to override this.

=cut

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

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut
