#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Config - Debconf meta-configuration module

=cut

=head1 DESCRIPTION

This package holds configuration values for debconf. It supplies defaults,
and allows them to be overridden by values pulled right out of the debconf
database itself.

=cut

package Debian::DebConf::Config;
use strict;
use Debian::DebConf::ConfigDb;

=head1 METHODS

=cut

=head2 dbdir

Where to store the database. 

=cut

sub dbdir {
	"./" # CHANGE THIS AT INSTALL TIME
}

=head2 tmpdir

Where to put temporary files. /tmp isn't used because I don't bother
opening these files safely, since that requires the use of Fcntl, which
isn't in perl-base

=cut

sub tmpdir {
	"./" # CHANGE THIS AT INSTALL TIME
}

=head2 frontend

The frontend to use. A value is pulled out of the database if possible,
otherwise a default is used.

If a value is passed to this function, it changes it temporarily (for
the lifetime of the program) to override what's in the database.

If DEBIAN_FRONTEND is set in the environment, it overrides all this.

=cut

{
	my $override_frontend='';

	sub frontend {
		return ucfirst($ENV{DEBIAN_FRONTEND})
			if exists $ENV{DEBIAN_FRONTEND};
		
		if (@_) {
			$override_frontend=ucfirst(shift);
		}
	
		return $override_frontend if ($override_frontend);
	
		my $ret='Dialog';
		my $question=Debian::DebConf::ConfigDb::getquestion(
			'debconf/frontend'
		);
		if ($question) {
			$ret=$question->value || $ret;
		}
		return $ret;
	}
}

=head2 priority

The lowest priority of questions you want to see. A value is pulled out of the
database if possible, otherwise a default is used.

If a value is passed to this function, it changes it temporarily (for
the lifetime of the program) to override what's in the database.

=cut

{
	my $override_priority='';

	sub priority {
		if (@_) {
			$override_priority=shift;
		}
	
		if ($override_priority) {
			return $override_priority;
		}
	
		my $ret='low';
		my $question=Debian::DebConf::ConfigDb::getquestion(
			'debconf/priority'
		);
		if ($question) {
			$ret=$question->value || $ret;
		}
		return $ret;
	}
}

=head2 showold

If true, then old questions the user has already seen are shown to them again.
A value is pulled out of the database if possible, otherwise a default of
false is used.

If a value is passed to this function, it changes it temporarily (for
the lifetime of the program) ro override what's in the database.

=cut

{
	my $override_showold='';
	
	sub showold {
		if (@_) {
			$override_showold=shift;
		}
		
		if ($override_showold) {
			return $override_showold;
		}
		
		my $ret='false';
		my $question=Debian::DebConf::ConfigDb::getquestion(
			'debconf/showold',
		);
		if ($question) {
			$ret=$question->value || $ret;
		}
		return $ret;
	}
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
