#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::Backup - backup writes to a db

=cut

package Debconf::DbDriver::Backup;
use strict;
use Debconf::Log qw{:all};
use base 'Debconf::DbDriver::Copy';

=head1 DESCRIPTION

This driver passes all reads and writes on to another database. But
copies of all writes are sent to a second database, too.

=cut

=head1 FIELDS

=over 4

=item db

The database to pass reads and writes to.

In the config file, the name of the database can be used.

=item backupdb

The database to write the backup to.

In the config file, the name of the database can be used.

=back

=cut

use fields qw(db backupdb);

=head1 METHODS

=head2 init

On initialization, convert db names to drivers.

=cut

sub init {
	my $this=shift;

	# Handle values from config file.
	foreach my $f (qw(db backupdb)) {
		if (! ref $this->{$f}) {
			my $db=$this->driver($this->{$f});
			unless (defined $f) {
				$this->error("could not find a db named \"$this->{$f}\"");
			}
			$this->{$f}=$db;
		}
	}
}

=head2 copy(item)

Ensures that the given item is backed up by doing a full copy of it into
the backup database.

=cut

sub copy {
	my $this=shift;
	my $item=shift;

	$this->SUPER::copy($item, $this->{db}, $this->{backupdb});
}

=item shutdown

Saves both databases.

=cut

sub shutdown {
	my $this=shift;
	
	$this->{backupdb}->shutdown(@_);
	$this->{db}->shutdown(@_);
}

# From here on out, the methods are of two types, as explained in
# the description above. Either it's a read, which goes to the db,
# or it's a write, which goes to the db, and, if that write succeeds,
# goes to the backup as well.
sub _query {
	my $this=shift;
	my $command=shift;
	shift; # this again
	
	return $this->{db}->$command(@_);
}

sub _change {
	my $this=shift;
	my $command=shift;
	shift; # this again

	my $ret=$this->{db}->$command(@_);
	if (defined $ret) {
		$this->{backupdb}->$command(@_);
	}
	return $ret;
}

sub iterator	{ $_[0]->_query('iterator', @_)		}
sub exists	{ $_[0]->_query('exists', @_)		}
sub addowner	{ $_[0]->_change('addowner', @_)	}
sub removeowner { $_[0]->_change('removeowner', @_)	}
sub owners	{ $_[0]->_query('owners', @_)		}
sub getfield	{ $_[0]->_query('getfield', @_)		}
sub setfield	{ $_[0]->_change('setfield', @_)	}
sub fields	{ $_[0]->_query('fields', @_)		}
sub getflag	{ $_[0]->_query('getflag', @_)		}
sub setflag	{ $_[0]->_change('setflag', @_)		}
sub flags	{ $_[0]->_query('flags', @_)		}
sub getvariable { $_[0]->_query('getvariable', @_)	}
sub setvariable { $_[0]->_change('setvariable', @_)	}
sub variables	{ $_[0]->_query('variables', @_)	}

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
