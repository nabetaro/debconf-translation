#!/usr/bin/perl

=head1 NAME

Debconf::Log - debconf log module

=cut

package Debconf::Log;
use strict;
use base qw(Exporter);
our @EXPORT_OK=qw(debug warn);
our %EXPORT_TAGS = (all => [@EXPORT_OK]); # Import :all to get everything.
require Debconf::Config; # not use; there are recursive use loops

=head1 DESCRIPTION

This is a log module for debconf.

This module uses Exporter.

=head1 METHODS

=over 4

=item debug

Outputs an infomational message. The first parameter specifies the type of
information that is being logged. If the user has specified a debug or log 
setting that matches the parameter, the message is output and/or logged.

Currently used types of information: user, developer, debug, db

=cut

my $log_open=0;
sub debug {
	my $type=shift;
	
	my $debug=Debconf::Config->debug;
	if ($debug && $type =~ /$debug/) {
		print STDERR "debconf ($type): ".join(" ", @_)."\n";
	}
	
	my $log=Debconf::Config->log;
	if ($log && $type =~ /$log/) {
		require Sys::Syslog;
		unless ($log_open) {
			Sys::Syslog::setlogsock('unix');
			Sys::Syslog::openlog('debconf', '', 'user');
			$log_open=1;
		}
		eval { # ignore all exceptions this throws
			Sys::Syslog::syslog('debug', "($type): ".
				join(" ", @_));
		};
	}
}

=item warn

Outputs a warning message. This overrides the builtin perl warn() command.

=cut

sub warn {
	print STDERR "debconf: ".join(" ", @_)."\n"
		unless Debconf::Config->nowarnings eq 'yes';
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
