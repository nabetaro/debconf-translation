#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::File - store database in flat file

=cut

package Debconf::DbDriver::File;
use strict;
use Debconf::Log qw(:all);
use Fcntl qw(:DEFAULT :flock);
use Debconf::Iterator;
use base 'Debconf::DbDriver::Cache';

=head1 DESCRIPTION

This is a debconf database driver that uses a single flat file for storing
the database. It uses more memory than most other drivers, has a slower
startup time (it reads the whole file at startup), and is very fast
thereafter until shutdown time (when it writes the whole file out). Of
course, the resulting single file is very handy to manage.

=head1 FIELDS

=over 4

=item filename

The file to use as the database

=item mode

The permissions to create the file with if it does not exist. Defaults to
600, since the file could contian passwords in some circumstances.

=item format

The Format object to use for reading and writing the file.

In the config file, just the name of the format to use, such as '822' can
be specified. Default is 822.

=back

=cut

use fields qw(filename mode format _fh);

=head1 METHODS

=head2 init

On initialization, load the entire file into memory and populate the cache.

=cut

sub init {
	my $this=shift;

	$this->{mode} = 0600 unless exists $this->{mode};
	$this->{format} = "822" unless exists $this->{format};

	$this->error("No format specified") unless $this->{format};
	eval "use Debconf::Format::$this->{format}";
	if ($@) {
		$this->error("Error setting up format object $this->{format}: $@");
	}
	$this->{format}="Debconf::Format::$this->{format}"->new;
	if (not ref $this->{format}) {
		$this->error("Unable to make format object");
	}

	$this->error("No filename specified") unless $this->{filename};

	debug "DbDriver $this->{name}" => "started; filename is $this->{filename}";
	
	# Make sure that the file exists, and set the mode too.
	if (! -e $this->{filename}) {
		sysopen(my $fh, $this->{filename}, 
				O_WRONLY|O_TRUNC|O_CREAT,$this->{mode}) or
			$this->error("could not open $this->{filename}");
		close $fh;
	}

	open ($this->{_fh}, $this->{filename}) or
		$this->error("could not open $this->{filename}: $!");
	if (! $this->{readonly}) {
		# Now lock the file with and flock locking. I don't wait on
		# locks, just error out. Since I open a lexical filehandle,
		# the lock is dropped when this object is destoryed.
		flock($this->{_fh}, LOCK_EX | LOCK_NB) or
			$this->error("$this->{filename} is locked by another process");
	}

	$this->SUPER::init(@_);

	# Now read in the whole file using the Format object.
	while (! eof $this->{_fh}) {
		my ($item, $cache)=$this->{format}->read($this->{_fh});
		$this->{cache}->{$item}=$cache;
	}
	# Close only if we are not keeping a lock.
	if ($this->{readonly}) {
		close $this->{_fh};
	}
}

=sub savedb

Save the entire cache out to the file.

=cut

sub savedb {
	my $this=shift;

	return if $this->{readonly};

	# Use sysopen and specify the mode just to be sure.
	sysopen(my $fh, $this->{filename},
			O_WRONLY|O_TRUNC|O_CREAT,$this->{mode}) or
		$this->error("could not write $this->{filename}: $!");		
	foreach my $item (sort keys %{$this->{cache}}) {
		$this->{format}->write($fh, $this->{cache}->{$item}, $item);
	}
	close $fh;
	return 1;
}

=sub load

Sorry bud, if it's not in the cache, it doesn't exist.

=cut

sub load {
	return undef;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
