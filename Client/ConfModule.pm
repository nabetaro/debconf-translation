#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Client::ConfModule - client module for ConfModules

=cut

=head1 SYNOPSIS

 	use Debian::DebConf::Client::ConfModule ':all';
 	version('2.0');
 	my $capb=capb('backup');
 	input("foo/bar");
 	my @ret=go();
 	if ($ret[0] == 30) {
 		# Back button pressed.
 		...
 	}
 	...

=cut

=head1 DESCRIPTION

This is a module to ease writing ConfModules for Debian's configuration
management system. It can communicate with a FrontEnd via the ConfModule
protocol. The design is that each command in the protocol is represented by
one function in this module (with the name lower-cased). Call the function and
pass in any parameters you want to follow the command. If the function is
called in scalar context, it will return any textual return code. If it is
called in list context, an array consiting of the numeric return code and the
textual return code will be returned.

This module uses Exporter to export all functions it defines. To import
everything, simply import ":all".

=cut

package Debian::DebConf::Client::ConfModule;
use Debian::DebConf::ConfigDb;
use Debian::DebConf::Config;
use Debian::DebConf::AutoSelect;
use strict;
use lib '.';
use Exporter;
use vars qw($AUTOLOAD @ISA @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

# List all valid commands here.
@EXPORT_OK=qw(version capb stop reset title input beginblock endblock go
	      unset set get register unregister previous_module
	      start_frontend fset fget subst purge metaget visible exist);

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
connected to it. Note that this function is always run when the
module is loaded in the usual way.

=cut

sub import {
	exec "/usr/share/debconf/frontend", $0, @ARGV
		unless $ENV{DEBIAN_HAS_FRONTEND};

	# Make the Exporter still work.
	Debian::DebConf::Client::ConfModule->export_to_level(1, @_);
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
	my @ret=split(/ /, $ret, 2);
	return @ret if wantarray;
	return $ret[0];
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
