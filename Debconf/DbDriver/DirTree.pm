#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::DirTree - store database in a directory hierarchy

=cut

package Debconf::DbDriver::DirTree;
use strict;
use Debconf::Log qw(:all);
use base 'Debconf::DbDriver::Directory';

=head1 DESCRIPTION

This is an extention to the Directory driver that uses a deeper directory
tree. I find such a tree easier to navigate, and it will also scale better
for huge databases.

=head1 FIELDS

=over 4

=item extention

This field is mandatory for this driver. If it is not set, it will be set
to ".dat" by default.

=back

=head1 METHODS

Note that the extention field is mandatory for this driver, so it checks
that on initialization.

=cut

sub init {
	my $this=shift;
	if (! defined $this->{extention} or ! length $this->{extention}) {
		$this->{extention}=".dat";
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

We actually use the item name as the filename, subdirs and all. However,
this means that we have to beware things like '/../..' as item names, so
some minimal sanity checking and sanitization is done.

We also still append the extention to the item name. And the extention is
_mandatory_ here; otherwise this would try to use filenames and directories
with the same names sometimes.

=cut

sub filename {
	my $this=shift;
	my $item=shift;
	$item =~ s/\.\.//g;
	return $item.$this->{extention};
}

=head2 iterator

Iterating over the whole directory hierarchy is the one annoying part of
this driver.

=cut

# TODO

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
		} while defined $ret and -d $this->filename($ret);
		$ret=~tr#:#/#;
		return $ret;
	});

	$this->SUPER::iterator($iterator);
}

=head2 remove(itemname)

Unlink a file. Then, rmdir any empty directories.

=cut

sub remove {
	my $this=shift;
	my $item=shift;

	my $ret=$this->SUPER::unlink($item);
	return $ret unless $ret;

	my $dir=$this->filename($item);
	while ($dir=~s:.*/[^/]*:$1: and length $dir) {
		rmdir $dir or last; # not empty, I presume
	}
	return $ret;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
