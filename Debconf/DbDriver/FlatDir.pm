#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::FlatDir - debconf db driver that stores items in files

=cut

package Debconf::DbDriver::FlatDir;
use strict;
use Debconf::Log qw{:all};
use base 'Debconf::DbDriver::Cache';

=head1 DESCRIPTION

This is a debconf database driver that uses a plain text file for
each individual item. The files are all contained in a single
subdirectory, and are named the same as the item name, except '/' is
replaced with ':' in the filename, and an optional extention is added.

Derived modules must implement the methods for reading and writing the
file contents.

=head1 FIELDS

=over 4

=item directory

The directory to put the files in.

=item extention

An optional extention to tack on the end of each filename.

=back

=cut

use fields qw(directory extention);

=head2 init

On initialization, we ensure that the directory exists.

=cut

sub init {
	my $this=shift;

	$this->{extention} = "" unless defined $this->{extention};

	$this->error("No directory specified") unless $this->{directory};
	if (not -d $this->{directory} and not $this->{readonly}) {
		mkdir $this->{directory} ||
			$this->error("mkdir $this->{directory}:$!");
	}
	if (not -d $this->{directory}) {
		$this->error($this->{directory}." does not exist");
	}
	# TODO: lock the directory too, for read, or write. (Fctrnl
	# locking?)

	debug "DbDriver $this->{name}" => "started; directory is $this->{directory}";
}

=head2 filename(itemname)

Converts the item name into a filename.

=cut

sub filename {
	my $this=shift;
	my $item=shift;
	$item =~ tr#/#:#;
	return $this->{directory}."/$item".$this->{extention};
}

=head2 iterate([iterator])

Iterate over the files with readdir.

=cut

sub iterate {
	my $this=shift;
	my $iterator=shift;
	
	if (not $iterator) {
		# uses dirhandle autovivification..
		opendir($iterator, $this->{directory}) || $this->error("opendir: $!");
		return $iterator;
	}

	my $ret=readdir($iterator);
	closedir($iterator) if not defined $ret;
	return $ret;
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

	return -e $this->filename($name);
}

=head2 remove(itemname)

Unlink a file.

=cut

sub remove {
	my $this=shift;
	my $name=shift;

	return if $this->{readonly} or not $this->accept($name);
	debug "DbDriver $this->{name}" => "removing $name";
	my $file=$this->filename($name);
	unlink $file or return undef;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
