#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Config - Debconf meta-configuration module

=cut

package Debian::DebConf::Config;
use strict;
use Debian::DebConf::ConfigDb;
use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(dbdir tmpdir frontend priority helpvisible showold);

=head1 DESCRIPTION

This package holds configuration values for debconf. It supplies defaults,
and allows them to be overridden by values pulled right out of the debconf
database itself.

=head1 METHODS

=over 4

=item dbdir

Where to store the database. 

=cut

sub dbdir {
	"./" # CHANGE THIS AT INSTALL TIME
}

=item tmpdir

Where to put temporary files. /tmp isn't used because I don't bother
opening these files safely, since that requires the use of Fcntl, which
isn't in perl-base

=cut

sub tmpdir {
	"./" # CHANGE THIS AT INSTALL TIME
}

=item frontend

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

=item priority

The lowest priority of questions you want to see. A value is pulled out of the
database if possible, otherwise a default is used.

If a value is passed to this function, it changes it temporarily (for
the lifetime of the program) to override what's in the database.

If DEBIAN_PRIORITY is set in the environment, it overrides all this.

=cut

{
	my $override_priority='';

	sub priority {
		return $ENV{DEBIAN_PRIORITY} if exists $ENV{DEBIAN_PRIORITY};
	
		if (@_) {
			$override_priority=shift;
		}
	
		if ($override_priority) {
			return $override_priority;
		}
	
		my $ret='medium';
		my $question=Debian::DebConf::ConfigDb::getquestion(
			'debconf/priority'
		);
		if ($question) {
			$ret=$question->value || $ret;
		}
		return $ret;
	}
}

=item helpvisible

Whether extended help should be displayed in some frontends. A value is
pulled out of the database if possible, otherwise a default is used.

If a value is passed to this function, it changes it perminantly.

=cut

sub helpvisible {
	my $question=Debian::DebConf::ConfigDb::getquestion(
		'debconf/helpvisible'
	);
	if ($question) {
		return $question->value unless @_;
		return $question->value(shift);
	}
	else {
		return 'true';
	}
}

=item showold

If true, then old questions the user has already seen are shown to them again.
A value is pulled out of the database if possible, otherwise a default of
false is used.

If a value is passed to this function, it changes it temporarily (for
the lifetime of the program) to override what's in the database.

=cut

{
	my $override_showold;
	
	sub showold {
		if (@_) {
			$override_showold=shift;
		}
		
		if (defined $override_showold) {
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

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
