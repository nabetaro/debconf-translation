#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::Cache - caching database driver

=cut

package Debconf::DbDriver::Cache;
use strict;
use Debconf::Log qw{:all};
use base 'Debconf::DbDriver';

=head1 DESCRIPTION

This is a base class for cacheable database drivers. Use this as the base
class for your driver if it makes sense to load and store items as a whole
(eg, if you are using text files to reprosent each item, or downloading whole
items over the net).

Don't use this base class for your driver if it makes more sense for your
driver to access individual parts of each item independantly (by
querying a (fast) database, for example).

=head1 FIELDS

=over 4

=item cache

A reference to a hash that holds the data for each loaded item in the
database. Each hash key is a item name; hash values are either undef
(used to indicate that a item used to exist here, but was deleted), or
are themselves references to hashes that hold the item data.

=back

=cut

use fields qw(cache);

=head1 ABSTRACT METHODS

Derived classes need to implement these methods.

=head2 iterate(itemname)

Iterate over all available items. If called with no arguments, it returns
an itarator. If called with the iterator passed in, it retuns the next
item in the sequence, or undef if there are no more.

=head2 exists(itemname)

Return true if the given item exists in the database.

=head2 load(itemname)

Load up the given item, and return a rather complex hashed structure to
represent the item. The structure is a reference to a hash with 4 items:

=over 4

=item owners

The value of this key must be a reference to a hash whose hash keys are
the owner names, and hash values are true.

=item fields

The value of this key must be a reference to a hash whose hash keys are
the field names, and hash values are the field values.

=item variables

The value of this key must be a reference to a hash whose hash keys are
the variable names, and hash values are the variable values.

=item flags

The value of this key must be a reference to a hash whose hash keys are
the flag names, and hash values are the flag values.

=back

If the item does not exist, return undef instead of the structure.

=head2 save(itemname,value)

This method will be passed a an identical hash reference with the same
format as what the load method should return. The data in the hash should
be saved.

=head2 remove(itemname)

Remove a item from the database.

=head1 METHODS

=head2 init

On initialization, the cache is empty.

=cut

sub init {
	my $this=shift;

	$this->{cache} = {} unless exists $this->{cache};
}

=cut

=head2 cached(itemname)

Ensure that a given item is loaded up in the cache. Returns the
cache entry for the item.

=cut

sub cached {
	my $this=shift;
	my $item=shift;

	unless (exists $this->{cache}->{$item}) {
		return unless $this->accept($item);
		debug "DbDriver $this->{name}" => "cache miss on $item";
		my $cache=$this->load($item);
		$this->{cache}->{$item}=$cache if $cache;
	}
	return $this->{cache}->{$item};
}

=head2 savedb

Synchronizes the underlying database with the cache. I don't keep track of
whether the cache is dirty, so the whole thing is flushed out.

Saving a item involves feeding the item from the cache into the underlying
database, and then telling the underlying db to save it.

However, if the item is undefined in the cache, we instead tell the
underlying db to remove it.

Returns true unless any of the operations fail.

=cut

sub savedb {
	my $this=shift;
	
	return if $this->{readonly};

	my $ret=1;
	foreach my $item (keys %{$this->{cache}}) {
		if (defined $this->{cache}->{$item}) {
			$ret=undef unless defined $this->save($item, $this->{cache}->{$item});
		}
		else {
			$ret=undef unless defined $this->remove($item);
		}
	}
	return $ret;
}

=head2 addowner(itemname, ownername)

Add an owner, if the underlying db is not readonly.

=cut

sub addowner {
	my $this=shift;
	my $item=shift;
	my $owner=shift;

	return if $this->{readonly};
	$this->cached($item);

	if (! defined $this->{cache}->{$item}) {
		return if ! $this->accept($item);
		debug "DbDriver $this->{name}" => "creating in-cache $item";
		# The item springs into existance.
		$this->{cache}->{$item}={
			owners => {},
			fields => {},
			variables => {},
			flags => {},
		}
	}

	$this->{cache}->{$item}->{owners}->{$owner}=1;
	return $owner;
}

=head2 removeowner(itemname, ownername)

Remove an owner from the cache. If all owners are removed, the item
is marked as removed in the cache.

=cut

sub removeowner {
	my $this=shift;
	my $item=shift;
	my $owner=shift;

	return if $this->{readonly};
	return unless $this->cached($item);

	delete $this->{cache}->{$item}->{owners}->{$owner};
	unless (keys %{$this->{cache}->{$item}->{owners}}) {
		$this->{cache}->{$item}=undef;
	}
	return $owner;
}

=head2 owners(itemname)

Pull owners out of the cache.

=cut

sub owners {
	my $this=shift;
	my $item=shift;

	return unless $this->cached($item);
	return keys %{$this->{cache}->{$item}->{owners}};
}

=head2 getfield(itemname, fieldname)

Pulls the field out of the cache.

=cut

sub getfield {
	my $this=shift;
	my $item=shift;
	my $field=shift;
	
	return unless $this->cached($item);
	return $this->{cache}->{$item}->{fields}->{$field};
}

=head2 setfield(itemname, fieldname, value)

Set the field in the cache, if the underlying db is not readonly.

=cut

sub setfield {
	my $this=shift;
	my $item=shift;
	my $field=shift;
	my $value=shift;

	return if $this->{readonly};
	return unless $this->cached($item);
	return $this->{cache}->{$item}->{fields}->{$field} = $value;	
}

=head2 fields(itemname)

Pulls the field list out of the cache.

=cut

sub fields {
	my $this=shift;
	my $item=shift;
	
	return unless $this->cached($item);
	return keys %{$this->{cache}->{$item}->{fields}};
}

=head2 getflag(itemname, flagname)

Pulls the flag out of the cache.

=cut

sub getflag {
	my $this=shift;
	my $item=shift;
	my $flag=shift;
	
	return unless $this->cached($item);
	return $this->{cache}->{$item}->{flags}->{$flag};
}

=head2 setflag(itemname, flagname, value)

Sets the flag in the cache, if the underlying db is not readonly.

=cut

sub setflag {
	my $this=shift;
	my $item=shift;
	my $flag=shift;
	my $value=shift;

	return if $this->{readonly};
	return unless $this->cached($item);
	return $this->{cache}->{$item}->{flags}->{$flag} = $value;
}

=head2 flags(itemname)

Pulls the flag list out of the cache.

=cut

sub flags {
	my $this=shift;
	my $item=shift;

	return unless $this->cached($item);
	return keys %{$this->{cache}->{$item}->{flags}};
}

=head2 getvariable(itemname, variablename)

Pulls the variable out of the cache.

=cut

sub getvariable {
	my $this=shift;
	my $item=shift;
	my $variable=shift;

	return unless $this->cached($item);
	return $this->{cache}->{$item}->{variables}->{$variable};
}

=head2 setvariable(itemname, variablename, value)

Sets the flag in the cache, if the underlying db is not readonly.

=cut

sub setvariable {
	my $this=shift;
	my $item=shift;
	my $variable=shift;
	my $value=shift;

	return if $this->{readonly};
	return unless $this->cached($item);
	return $this->{cache}->{$item}->{variables}->{$variable} = $value;
}

=head2 variables(itemname)

Pulls the variable list out of the cache.

=cut

sub variables {
	my $this=shift;
	my $item=shift;

	return unless $this->cached($item);
	return keys %{$this->{cache}->{$item}->{variables}};
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
