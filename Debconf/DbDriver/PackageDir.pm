#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::PackageDir - store database in a directory

=cut

package Debconf::DbDriver::PackageDir;
use strict;
use Debconf::Log qw(:all);
use IO::File;
use Fcntl qw(:DEFAULT :flock);
use Debconf::Iterator;
use base 'Debconf::DbDriver::Directory';

=head1 DESCRIPTION

This is a debconf database driver that uses a plain text file for each
individual "subdirectory" of the internal tree.

It uses a Format module to handle reading and writing the files, so the
files can be of any format.

=head1 FIELDS

=over 4

=item directory

The directory to put the files in.

=item extension

An optional extension to tack on the end of each filename.

=item mode

The (octal) permissions to create the files with if they do not exist.
Defaults to 600, since the files could contain passwords in some 
circumstances.

=item format

The Format object to use for reading and writing files. 

In the config file, just the name of the format to use, such as '822' can
be specified. Default is 822.

=back

=head1 METHODS

=cut

use fields qw(mode _loaded);

=head2 init

On initialization, we ensure that the directory exists.

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
	$this->SUPER::init(@_);
}

=head2 loadfile(filename)

Loads up a file by name, after checking to make sure it's not ben loaded
already. Omit the directory from the filename.

=cut

sub loadfile {
	my $this=shift;
	my $file=$this->{directory}."/".shift;

	return if $this->{_loaded}->{$file};
	$this->{_loaded}->{$file}=1;
	
	debug "db $this->{name}" => "loading $file";
	return unless -e $file;

	my $fh=IO::File->new;
	open($fh, $file) or $this->error("$file: $!");
	my @item = $this->{format}->read($fh);
	while (@item) {
		$this->cacheadd(@item);
		@item = $this->{format}->read($fh);
	}
	close $fh;
}

=head2 load(itemname)

After checking the cache, find the file that contains the item, then use
the format object to load up the item (and all other items from that file,
which get cached).

=cut

sub load {
	my $this=shift;
	my $item=shift;
	$this->loadfile($this->filename($item));
}

=head2 filename(itemname)

Converts the item name into a filename. (Minus the base directory.)

=cut

sub filename {
	my $this=shift;
	my $item=shift;

	if ($item =~ m!^([^/]+)(?:/|$)!) {
		return $1.$this->{extension};
	}
	else {
		$this->error("failed parsing item name \"$item\"\n");
	}
}

=head2 iterator

This iterator is not very well written in general, as it loads up all files
that were not previously loaded, and then lets the super class iterate over
the populated cache. However, all iteration in debconf so far iterates over
the whole set, so it doesn't matter.

=cut

sub iterator {
	my $this=shift;
	
	my $handle;
	opendir($handle, $this->{directory}) ||
		$this->error("opendir: $!");

	while (my $file=readdir($handle)) {
		next if length $this->{extension} and
		        not $file=~m/$this->{extension}/;
		next unless -f $this->{directory}."/".$file;
		next if $file eq '.lock' || $file =~ /-old$/;
		$this->loadfile($file);
	}

	# grandparent's method; parent's does unwanted stuff
	$this->SUPER::iterator;
}

=head2 exists(itemname)

Check the cache first, then check to see if a file that might contain the
item exists, load it, and test existence. 

=cut

sub exists {
	my $this=shift;
	my $name=shift;
	# Check the cache first.
	my $incache=$this->Debconf::DbDriver::Cache::exists($name);
	return $incache if (!defined $incache or $incache);
	my $file=$this->{directory}.'/'.$this->filename($name);
	return unless -e $file;

	$this->load($name);
	
	# Now check the cache again; if it exists load will have put it
	# into the cache.
	return $this->Debconf::DbDriver::Cache::exists($name);
}

=head2 shutdown

This has to break the abstraction and access the underlying cache directly.

=cut

sub shutdown {
	my $this=shift;

	return if $this->{readonly};

	my (%files, %filecontents, %killfiles, %dirtyfiles);
	foreach my $item (keys %{$this->{cache}}) {
		my $file=$this->filename($item);
		$files{$file}++;
		
		if (! defined $this->{cache}->{$item}) {
			$killfiles{$file}++;
			delete $this->{cache}->{$item};
		}
		else {
			push @{$filecontents{$file}}, $item;
		}

		if ($this->{dirty}->{$item}) {
			$dirtyfiles{$file}++;
			$this->{dirty}->{$item}=0;
		}
	}

	foreach my $file (keys %files) {
		if (! $filecontents{$file} && $killfiles{$file}) {
			debug "db $this->{name}" => "removing $file";
			my $filename=$this->{directory}."/".$file;
			unlink $filename or
				$this->error("unable to remove $filename: $!");
			if (-e $filename."-old") {
				unlink $filename."-old" or
					$this->error("unable to remove $filename-old: $!");
			}
		}
		elsif ($dirtyfiles{$file}) {
			debug "db $this->{name}" => "saving $file";
			my $filename=$this->{directory}."/".$file;
		
			sysopen(my $fh, $filename."-new",
			                O_WRONLY|O_TRUNC|O_CREAT,$this->{mode}) or
				$this->error("could not write $filename-new: $!");
			$this->{format}->beginfile;
			foreach my $item (@{$filecontents{$file}}) {
				$this->{format}->write($fh, $this->{cache}->{$item}, $item)
					or $this->error("could not write $filename-new: $!");
			}
			$this->{format}->endfile;

			# Ensure -new is flushed.
			$fh->flush or $this->error("could not flush $filename-new: $!");
			# Ensure it is synced, because I've had problems with
			# disk caching resulting in truncated files.
			$fh->sync or $this->error("could not sync $filename-new: $!");

			# Now rename the old file to -old (if doing backups),
			# and put -new in its place.
			if (-e $filename && $this->{backup}) {
				rename($filename, $filename."-old") or
					debug "db $this->{name}" => "rename failed: $!";
			}
			rename($filename."-new", $filename) or
				$this->error("rename failed: $!");
		}
	}
	
	$this->SUPER::shutdown(@_);
	return 1;
}

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
