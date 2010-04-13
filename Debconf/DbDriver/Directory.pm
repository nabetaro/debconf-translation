#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::Directory - store database in a directory

=cut

package Debconf::DbDriver::Directory;
use strict;
use Debconf::Log qw(:all);
use IO::File;
use POSIX ();
use Fcntl qw(:DEFAULT :flock);
use Debconf::Iterator;
use base 'Debconf::DbDriver::Cache';

=head1 DESCRIPTION

This is a debconf database driver that uses a plain text file for
each individual item. The files are contained in a directory tree, and
are named according to item names, with slashes replaced by colons.

It uses a Format module to handle reading and writing the files, so the
files can be of any format.

This is a foundation for other DbDrivers, and is not itself usable as one.

=head1 FIELDS

=over 4

=item directory

The directory to put the files in.

=item extension

An optional extension to tack on the end of each filename.

=item format

The Format object to use for reading and writing files. 

In the config file, just the name of the format to use, such as '822' can
be specified. Default is 822.

=back

=head1 METHODS

=cut

use fields qw(directory extension lock format);

=head2 init

On initialization, we ensure that the directory exists.

=cut

sub init {
	my $this=shift;

	$this->{extension} = "" unless exists $this->{extension};
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

	$this->error("No directory specified") unless $this->{directory};
	if (not -d $this->{directory} and not $this->{readonly}) {
		mkdir $this->{directory} ||
			$this->error("mkdir $this->{directory}:$!");
	}
	if (not -d $this->{directory}) {
		$this->error($this->{directory}." does not exist");
	}
	debug "db $this->{name}" => "started; directory is $this->{directory}";
	
	if (! $this->{readonly}) {
		# Now lock the directory. I use a lockfile named '.lock' in the
		# directory, and flock locking. I don't wait on locks, just
		# error out. Since I open a lexical filehandle, the lock is
		# dropped when this object is destroyed.
		open ($this->{lock}, ">".$this->{directory}."/.lock") or
			$this->error("could not lock $this->{directory}: $!");
		while (! flock($this->{lock}, LOCK_EX | LOCK_NB)) {
			next if $! == &POSIX::EINTR;
			$this->error("$this->{directory} is locked by another process: $!");
			last;
		}
	}
}

=head2 load(itemname)

Uses the format object to load up the item.

=cut

sub load {
	my $this=shift;
	my $item=shift;

	debug "db $this->{name}" => "loading $item";
	my $file=$this->{directory}.'/'.$this->filename($item);
	return unless -e $file;

	my $fh=IO::File->new;
	open($fh, $file) or $this->error("$file: $!");
	$this->cacheadd($this->{format}->read($fh));
	close $fh;
}

=head2 save(itemname,value)

Use the format object to write out the item.

Makes sure that items with a type of "password" are written out to mode 600
files.

=cut

sub save {
	my $this=shift;
	my $item=shift;
	my $data=shift;
	
	return unless $this->accept($item);
	return if $this->{readonly};
	debug "db $this->{name}" => "saving $item";
	
	my $file=$this->{directory}.'/'.$this->filename($item);

	# Write out passwords mode 600.
	my $fh=IO::File->new;
	if ($this->ispassword($item)) {
		sysopen($fh, $file."-new", O_WRONLY|O_TRUNC|O_CREAT, 0600)
			or $this->error("$file-new: $!");
	}
	else {
		open($fh, ">$file-new") or $this->error("$file-new: $!");
	}
	$this->{format}->beginfile;
	$this->{format}->write($fh, $data, $item)
		or $this->error("could not write $file-new: $!");
	$this->{format}->endfile;
	
	# Ensure it is synced, to disk buffering doesn't result in
	# inconsistencies.
	$fh->flush or $this->error("could not flush $file-new: $!");
	$fh->sync or $this->error("could not sync $file-new: $!");
	close $fh or $this->error("could not close $file-new: $!");
	
	# Now rename the old file to -old (if doing backups),
	# and put -new in its place.
	if (-e $file && $this->{backup}) {
		rename($file, $file."-old") or
			debug "db $this->{name}" => "rename failed: $!";
	}
	rename("$file-new", $file) or $this->error("rename failed: $!");
}

=sub shutdown

All this function needs to do is unlock the database. Saving happens
whenever something is saved.

=cut

sub shutdown {
	my $this=shift;
	
	$this->SUPER::shutdown(@_);
	delete $this->{lock};
	return 1;
}

=head2 exists(itemname)

Simply check for file existance, after querying the cache.

=cut

sub exists {
	my $this=shift;
	my $name=shift;
	
	# Check the cache first.
	my $incache=$this->SUPER::exists($name);
	return $incache if (!defined $incache or $incache);

	return -e $this->{directory}.'/'.$this->filename($name);
}

=head2 remove(itemname)

Unlink a file.

=cut

sub remove {
	my $this=shift;
	my $name=shift;

	return if $this->{readonly} or not $this->accept($name);
	debug "db $this->{name}" => "removing $name";
	my $file=$this->{directory}.'/'.$this->filename($name);
	unlink $file or return undef;
	if (-e $file."-old") {
		unlink $file."-old" or return undef;
	}
	return 1;
}

=head2 accept(itemname)

Accept is overridden to reject any item names that contain either "../" or
"/..". Either could be used to break out of the directory tree.

=cut

sub accept {
	my $this=shift;
	my $name=shift;

	return if $name=~m#\.\./# or $name=~m#/\.\.#;
	$this->SUPER::accept($name, @_);
}

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
