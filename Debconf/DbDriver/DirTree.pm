#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::DirTree - store database in a directory hierarchy

=cut

package Debconf::DbDriver::DirTree;
use strict;
use Debconf::Log qw(:all);
use base 'Debconf::DbDriver::Directory';

=head1 DESCRIPTION

This is an extension to the Directory driver that uses a deeper directory
tree. I find such a tree easier to navigate, and it will also scale better
for huge databases on ext2. It does use a little more disk space/inodes
though.

=head1 FIELDS

=over 4

=item extension

This field is mandatory for this driver. If it is not set, it will be set
to ".dat" by default.

=back

=head1 METHODS

Note that the extension field is mandatory for this driver, so it checks
that on initialization.

=cut

sub init {
	my $this=shift;
	if (! defined $this->{extension} or ! length $this->{extension}) {
		$this->{extension}=".dat";
	}
	$this->SUPER::init(@_);
}

=head2 save(itemname,value)

Before saving as usual, we have to make sure the subdirectory exists.

=cut

sub save {
	my $this=shift;
	my $item=shift;

	return unless $this->accept($item);
	return if $this->{readonly};
	
	my @dirs=split(m:/:, $this->filename($item));
	pop @dirs; # the base filename
	my $base=$this->{directory};
	foreach (@dirs) {
		$base.="/$_";
		next if -d $base;
		mkdir $base or $this->error("mkdir $base: $!");
	}
	
	$this->SUPER::save($item, @_);
}

=head2 filename(itemname)

We actually use the item name as the filename, subdirs and all.

We also still append the extension to the item name. And the extension is
_mandatory_ here; otherwise this would try to use filenames and directories
with the same names sometimes.

=cut

sub filename {
	my $this=shift;
	my $item=shift;
	$item =~ s/\.\.//g;
	return $item.$this->{extension};
}

=head2 iterator

Iterating over the whole directory hierarchy is the one annoying part of
this driver.

=cut

sub iterator {
	my $this=shift;
	
	# Stack of pending directories.
	my @stack=();
	my $currentdir="";
	my $handle;
	opendir($handle, $this->{directory}) or
		$this->error("opendir: $this->{directory}: $!");
		
	my $iterator=Debconf::Iterator->new(callback => sub {
		my $i;
		while ($handle or @stack) {
			while (@stack and not $handle) {
				$currentdir=pop @stack;
				opendir($handle, "$this->{directory}/$currentdir") or
					$this->error("opendir: $this->{directory}/$currentdir: $!");
			}
			$i=readdir($handle);
			if (not defined $i) {
			closedir $handle;
				$handle=undef;
				next;
			}
			next if $i eq '.lock' || $i =~ /-old$/;
			if (-d "$this->{directory}/$currentdir$i") {
				if ($i ne '..' and $i ne '.') {
					push @stack, "$currentdir$i/";
				}
				next;
			}
			# Ignore files w/o our extension, and strip it.
			next unless $i=~s/$this->{extension}$//;
			return $currentdir.$i;
		}
		return undef;
	});

	$this->SUPER::iterator($iterator);
}

=head2 remove(itemname)

Unlink a file. Then, rmdir any empty directories.

=cut

sub remove {
	my $this=shift;
	my $item=shift;

	# Do actual remove.
	my $ret=$this->SUPER::remove($item);
	return $ret unless $ret;

	# Clean up.
	my $dir=$this->filename($item);
	while ($dir=~s:(.*)/[^/]*:$1: and length $dir) {
		rmdir "$this->{directory}/$dir" or last; # not empty, I presume
	}
	return $ret;
}

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
