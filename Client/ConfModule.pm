#!/usr/bin/perl -w

=head1 NAME

   DebConf::Client::ConfModule - client module for ConfModules

=cut

=head1 SYNOPSIS

	use DebConf::Client::ConfModule ':all';
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

package ConfModule;
use strict;
use Exporter;
use vars qw($AUTOLOAD @ISA @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

# List all valid commands here.
@EXPORT_OK=qw(version capb stop reset title text input beginblock endblock go
		   note unset set get register unregister previous_module
		   start_frontend);

# Import :all to get everything.		   
%EXPORT_TAGS = (all => [@EXPORT_OK]);

# Set up valid command lookup hash.
my %commands;
map { $commands{uc $_}=1; } @EXPORT_OK;

# Unbuffered output is required.
$|=1;

=head2 start_frontend

Ensure that a FrontEnd is running. This is only for use by external programs
that still want to use a FrontEnd. It's a little hackish. If DEBIAN_FRONTEND
is set, a frontend is assumed to be running. If not, the frontend will
actually be started up and told to run this program again, with the variable
set.

=cut

sub start_frontend {
	unless ($ENV{DEBIAN_FRONTEND}) {
		$ENV{DEBIAN_FRONTEND}=1;
		exec("client/start-frontend", $0) || die $!;
	}
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
