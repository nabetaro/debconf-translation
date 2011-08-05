#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::File - store database in flat file

=cut

package Debconf::DbDriver::File;
use strict;
use Debconf::Log qw(:all);
use POSIX ();
use Fcntl qw(:DEFAULT :flock);
use IO::Handle;
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

The (octal) permissions to create the file with if it does not exist.
Defaults to 600, since the file could contain passwords in some circumstances.

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

	if (exists $this->{mode}) {
		# Convert user input to octal.
		$this->{mode} = oct($this->{mode});
	}
	else {
		$this->{mode} = 0600;
	}
	$this->{format} = "822" unless exists $this->{format};
	$this->{backup} = 1 unless exists $this->{backup};

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

	debug "db $this->{name}" => "started; filename is $this->{filename}";
	
	# Make sure that the file exists, and set the mode too.
	if (! -e $this->{filename}) {
		my ($directory)=$this->{filename}=~m!^(.*)/[^/]+!;
		if (! -d $directory) {
			mkdir $directory || $this->error("mkdir $directory:$!");
		}

		$this->{backup}=0;
		sysopen(my $fh, $this->{filename}, 
				O_WRONLY|O_TRUNC|O_CREAT,$this->{mode}) or
			$this->error("could not open $this->{filename}");
		close $fh;
	}

	my $implicit_readonly=0;
	if (! $this->{readonly}) {
		# Open file for read but also with write access so
		# exclusive lock can be done portably.
		if (open ($this->{_fh}, "+<", $this->{filename})) {
			# Now lock the file with flock locking. I don't
			# wait on locks, just error out. Since I open a
			# lexical filehandle, the lock is dropped when
			# this object is destroyed.
			while (! flock($this->{_fh}, LOCK_EX | LOCK_NB)) {
				next if $! == &POSIX::EINTR;
				$this->error("$this->{filename} is locked by another process: $!");
				last;
			}
		}
		else {
			# fallthrough to readonly mode
			$implicit_readonly=1;
		}
	}
	if ($this->{readonly} || $implicit_readonly) {
		if (! open ($this->{_fh}, "<", $this->{filename})) {
			$this->error("could not open $this->{filename}: $!");
			return; # always abort, even if not throwing fatal error
		}
	}

	$this->SUPER::init(@_);

	debug "db $this->{name}" => "loading database";

	# Now read in the whole file using the Format object.
	while (! eof $this->{_fh}) {
		my ($item, $cache)=$this->{format}->read($this->{_fh});
		$this->{cache}->{$item}=$cache;
	}
	# Close only if we are not keeping a lock.
	if ($this->{readonly} || $implicit_readonly) {
		close $this->{_fh};
	}
}

=sub shutdown

Save the entire cache out to the file, then close the file.

=cut

sub shutdown {
	my $this=shift;

	return if $this->{readonly};

	if (grep $this->{dirty}->{$_}, keys %{$this->{cache}}) {
		debug "db $this->{name}" => "saving database";
	}
	else {
		debug "db $this->{name}" => "no database changes, not saving";

		# But do drop the lock.
		delete $this->{_fh};

		return 1;
	}

	# Write out the file to -new, locking it as we go.
	sysopen(my $fh, $this->{filename}."-new",
			O_WRONLY|O_TRUNC|O_CREAT,$this->{mode}) or
		$this->error("could not write $this->{filename}-new: $!");
	while (! flock($fh, LOCK_EX | LOCK_NB)) {
		next if $! == &POSIX::EINTR;
		$this->error("$this->{filename}-new is locked by another process: $!");
		last;
	}
	$this->{format}->beginfile;
	foreach my $item (sort keys %{$this->{cache}}) {
		next unless defined $this->{cache}->{$item}; # skip deleted
		$this->{format}->write($fh, $this->{cache}->{$item}, $item)
			or $this->error("could not write $this->{filename}-new: $!");
	}
	$this->{format}->endfile;

	# Ensure -new is flushed.
	$fh->flush or $this->error("could not flush $this->{filename}-new: $!");
	# Ensure it is synced, because I've had problems with disk caching
	# resulting in truncated files.
	$fh->sync or $this->error("could not sync $this->{filename}-new: $!");

	# Now rename the old file to -old (if doing backups), and put -new 
	# in its place.
	if (-e $this->{filename} && $this->{backup}) {
		rename($this->{filename}, $this->{filename}."-old") or
			debug "db $this->{name}" => "rename failed: $!";
	}
	rename($this->{filename}."-new", $this->{filename}) or
		$this->error("rename failed: $!");

	# Now drop the lock on -old (the lock on -new will be removed
	# when this function returns and $fh goes out of scope).
	delete $this->{_fh};

	return 1;
}

=sub load

Sorry bud, if it's not in the cache, it doesn't exist.

=cut

sub load {
	return undef;
}

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
