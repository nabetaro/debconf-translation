#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::Tree - mount drivers onto a tree

=cut

package Debconf::DbDriver::Tree;
use strict;
use base qw(Debconf::DbDriver);

=head1 DESCRIPTION

This class collects several drivers together, mounting them onto various
points on a tree, similar to mounting drives at various points in a
filesystem.

=head1 FIELDS

=over 4

=item tree

A reference to a hash whose keys are the mountpoints and whose values are
the drivers to mount. Mountpoints are specified without a leading "/", so
use "" as a mountpoint to mount something at the root of the tree, "foo/" to
mount it at "directory" foo, and so on. 

=back

=head1 METHODS

=head2 init

On initialization, make sure there is a tree hash.

=cut

sub init {
	my $this=shift;

	$this->{tree} = {} unless $this->{tree};
	$this->{_map} = {};
}

=head2 iterate

Iterates over all the items in all the mounted drivers.

=cut

sub iterate {
	my $this=shift;
	my $iterator=shift;

	if (not $iterator) {
		# Use a reference to a list as the iterator.
		# The list is composed of triplets of items The first item in
		# the triple is the db driver, the second is its iterator,
		# and the third is its mountpoint.
		$iterator=
			[map { $this->{tree}->$_ => $this->{tree}->$_->iterate, $_ }
				keys %{$this->{tree}}];
	}

	# Iterate the first thing in our list.
	my $ret=$iterator->[0]->iterate($iterator->[1]);
	return $iterator->[2].$ret if defined $ret; # add mountpoint
	
	# That one's done, so remove it and its iterator and mountpoint
	# from the list, and move on to the next.
	shift @{$iterator};
	shift @{$iterator};
	shift @{$iterator};
	return unless @{$iterator}; # all done
	return $this->iterate($iterator); # look, ma! useless tail recursion!
}

=head2 savedb

Passes the request on to all the drivers. If any fail, returns undef.

=cut

sub savedb {
	my $this=shift;

	my $ret=1;
	foreach my $driver (values %{$this->{tree}}) {
		$ret=undef unless defined $driver->savedb(@_);
	}
	return $ret;
}

# Now for all the rest we just figure out which driver to use, 
# remove the mountpoint from the item name, and pass the request on to the
# driver. This helper sub does that.
sub _do {
	my $this=shift;
	my $command=shift;
	shift; # $this again..
	my $item=shift;

	# Prefer the longest matching mountpoint in the tree.
	# Since this is a little slow, I memoize it, using $this->_map
	unless ($this->{_map}->{$item}) {
		my $length=0;
		my $match=undef;
		foreach my $mountpoint (keys %{$this->{tree}}) {
			if (length $mountpoint > $length &&
			    $item =~ /^\Q$mountpoint\E/) {
				$length=length $mountpoint;
				$match=$mountpoint;
			}
		}
		$this->{_map}->{$item} = $match;
	}
	my $mountpoint=$this->{_map}->{$item};
	$item=~s/^\Q$mountpoint\E//;
	return $this->{tree}->{$mountpoint}->$command($item, @_);
}

sub exists	{ $_[0]->_do('exists', @_) }
sub addowner	{ $_[0]->_do('addowner', @_) }
sub removeowner { $_[0]->_do('removeowner', @_) }
sub getfield	{ $_[0]->_do('getfield', @_) }
sub setfield	{ $_[0]->_do('setfield', @_) }
sub fields	{ $_[0]->_do('fields', @_) }
sub getflag	{ $_[0]->_do('getflag', @_) }
sub setflag	{ $_[0]->_do('setflag', @_) }
sub flags	{ $_[0]->_do('flags', @_) }
sub getvariable { $_[0]->_do('getvariable', @_) }
sub setvariable { $_[0]->_do('setvariable', @_) }
sub variables	{ $_[0]->_do('variables', @_) }

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
