#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::FlatDir - debconf db driver that stores items in files

=cut

package Debconf::DbDriver::FlatDir;
use strict;
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

	die "No directory specified\n" unless $this->{directory};
	if (not -d $this->{directory} and not $this->{readonly}) {
		mkdir $this->{directory} ||
			die "mkdir $this->{directory}:$!";
	}
	if (not -d $this->{directory}) {
		die $this->{directory}." does not exist\n";
	}
	# TODO: lock the directory too, for read, or write. (Fctrnl
	# locking?)
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
		opendir($iterator, $this->{directory}) || die "opendir: $!";
		return $iterator;
	}

	my $ret=readdir($iterator);
	closedir($iterator) if not defined $ret;
	return $ret;
}

=head2 exists(itemname)

Simply check for file existance.

=cut

sub exists {
	my $this=shift;
	return -e $this->filename(shift);
}

=head2 remove(itemname)

Unlink a file.

=cut

sub remove {
	my $this=shift;
	return if $this->{readonly};
	my $file=$this->filename(shift);
	unlink $file or return undef;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
