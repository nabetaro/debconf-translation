#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::Directory - store database in a directory

=cut

package Debconf::DbDriver::Directory;
use strict;
use Debconf::Log qw(:all);
use IO::File;
use Fcntl qw(:DEFAULT :flock);
use Debconf::Iterator;
use base 'Debconf::DbDriver::Cache';

=head1 DESCRIPTION

This is a debconf database driver that uses a plain text file for
each individual item. The files are contained in a directory tree, and
are named according to item names, with slashes replaces by colons.

It uses a Format module to handle reading and writing the files, so the
files can be of any format.

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
		# dropped when this object is destoryed.
		open ($this->{lock}, ">".$this->{directory}."/.lock") or
			$this->error("could not lock $this->{directory}: $!");
		flock($this->{lock}, LOCK_EX | LOCK_NB) or
			$this->error("$this->{directory} is locked by another process");
	}
}

=head2 load(itemname)

Uses the format object to load up the item.

=cut

sub load {
	my $this=shift;
	my $item=shift;

	return unless $this->accept($item);
	debug "db $this->{name}" => "loading $item";
	my $file=$this->{directory}.'/'.$this->filename($item);
	return unless -e $file;

	my $fh=IO::File->new;
	open($fh, $file) or $this->error("$file: $!");
	my $ret=$this->{format}->read($fh);
	close $fh;
	return $ret;
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
	$this->{format}->write($fh, $data, $item);
	$this->{format}->endfile;
	close $fh;
	rename("$file-new", $file) or $this->error("rename failed: $!");
}

=head2 filename(itemname)

Converts the item name into a filename. (Minus the base directory.)

=cut

sub filename {
	my $this=shift;
	my $item=shift;
	$item =~ tr#/#:#;
	return $item.$this->{extension};
}

=head2 iterator

Returns an iterator that can iterate over the files with readdir.

=cut

sub iterator {
	my $this=shift;
	
	# uses dirhandle autovivification..
	my $handle;
	opendir($handle, $this->{directory}) ||
		$this->error("opendir: $!");

	my $iterator=Debconf::Iterator->new(callback => sub {
		my $ret;
		do {
			$ret=readdir($handle);
			closedir($handle) if not defined $ret;
			next if $ret eq '.lock'; # ignore lock file
			next if length $this->{extension} and
			        not $ret=~s/$this->{extension}//;
		} while defined $ret and -d "$this->{directory}/$ret";
		$ret=~tr#:#/#;
		return $ret;
	});

	$this->SUPER::iterator($iterator);
}

=head2 exists(itemname)

Simply check for file existance, after querying the cache.

=cut

sub exists {
	my $this=shift;
	my $name=shift;
	
	return unless $this->accept($name);
	
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
	unlink $this->{directory}.'/'.$this->filename($name) or return undef;
	return 1;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
