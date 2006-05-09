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
(eg, if you are using text files to represent each item, or downloading whole
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

=item dirty

A reference to a hash that holds data about what items in the cache are
dirty. Each hash key is an item name; if the value is true, the item is
dirty.

=back

=cut

use fields qw(cache dirty);

=head1 ABSTRACT METHODS

Derived classes need to implement these methods in most cases.

=head2 load(itemname)

Ensure that the given item is loaded. It will want to call back to the
cacheadd method (see below) to add an item or items to the cache.

=head2 save(itemname,value)

This method will be passed a an identical hash reference with the same
format as what the load method should return. The data in the hash should
be saved.

=head2 remove(itemname)

Remove a item from the database.

=head1 METHODS

=head2 iterator

Derived classes should override this method and construct their own
iterator. Then at the end call:

	 $this->SUPER::iterator($myiterator);

This method will take it from there.

=cut

sub iterator {
	my $this=shift;
	my $subiterator=shift;

	my @items=keys %{$this->{cache}};
	my $iterator=Debconf::Iterator->new(callback => sub {
		# So, the trick is we will first iterate over everything in
		# the cache. Then, we will let the underlying driver take
		# over and iterate everything outside the cache. If it
		# returns something that is in the cache (and we're
		# weeding), or something that is marked deleted in cache, just
		# ask it for the next thing.
		while (my $item = pop @items) {
			next unless defined $this->{cache}->{$item};
			return $item;
		}
		return unless $subiterator;
		my $ret;
		do {
			$ret=$subiterator->iterate;
		} while defined $ret and exists $this->{cache}->{$ret};
		return $ret;
	});
	return $iterator;
}

=head2 exists(itemname)

Derived classes should override this method. Be sure to call
SUPER::exists(itemname) first, and return whatever it returns
*unless* it returns 0, to check if the item exists in the cache
first!

This method returns one of three values:

true  -- yes, it's in the cache
undef -- marked as deleted in the cache, so does not exist
0     -- not in the cache; up to derived class now

=cut

sub exists {
	my $this=shift;
	my $item=shift;

	return $this->{cache}->{$item}
		if exists $this->{cache}->{$item};
	return 0;
}

=head2 init

On initialization, the cache is empty.

=cut

sub init {
	my $this=shift;

	$this->{cache} = {} unless exists $this->{cache};
}

=head2 cacheadd(itemname, entry)

Derived classes can call this method to add an item to the cache. If the item
is already in the cache, no change will be made.

The entry field is a rather complex hashed structure to represent
the item. The structure is a reference to a hash with 4 items:

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

=cut

sub cacheadd {
	my $this=shift;
	my $item=shift;
	my $entry=shift;

	return if exists $this->{cache}->{$item};

	$this->{cache}->{$item}=$entry;
	$this->{dirty}->{$item}=0;
}

=head2 cachedata(itemname)

Looks up an item in the cache and returns a complex data structure of the same
format as the cacheadd() entry parameter.

=cut

sub cachedata {
	my $this=shift;
	my $item=shift;
	
	return $this->{cache}->{$item};
}

=head2 cached(itemname)

Ensure that a given item is loaded up in the cache.

=cut

sub cached {
	my $this=shift;
	my $item=shift;

	unless (exists $this->{cache}->{$item}) {
		debug "db $this->{name}" => "cache miss on $item";
		$this->load($item);
	}
	return $this->{cache}->{$item};
}

=head2 shutdown

Synchronizes the underlying database with the cache.

Saving a item involves feeding the item from the cache into the underlying
database, and then telling the underlying db to save it.

However, if the item is undefined in the cache, we instead tell the
underlying db to remove it.

Returns true unless any of the operations fail.

=cut

sub shutdown {
	my $this=shift;
	
	return if $this->{readonly};

	my $ret=1;
	foreach my $item (keys %{$this->{cache}}) {
		if (not defined $this->{cache}->{$item}) {
			# Remove item, then remove marker in cache.
			$ret=undef unless defined $this->remove($item);
			delete $this->{cache}->{$item};
		}
		elsif ($this->{dirty}->{$item}) {
			$ret=undef unless defined $this->save($item, $this->{cache}->{$item});
			$this->{dirty}->{$item}=0;
		}
	}
	return $ret;
}

=head2 addowner(itemname, ownername, type)

Add an owner, if the underlying db is not readonly, and if the given
type is acceptable.

=cut

sub addowner {
	my $this=shift;
	my $item=shift;
	my $owner=shift;
	my $type=shift;

	return if $this->{readonly};
	$this->cached($item);

	if (! defined $this->{cache}->{$item}) {
		return if ! $this->accept($item, $type);
		debug "db $this->{name}" => "creating in-cache $item";
		# The item springs into existance.
		$this->{cache}->{$item}={
			owners => {},
			fields => {},
			variables => {},
			flags => {},
		}
	}

	if (! exists $this->{cache}->{$item}->{owners}->{$owner}) {
		$this->{cache}->{$item}->{owners}->{$owner}=1;
		$this->{dirty}->{$item}=1;
	}
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

	if (exists $this->{cache}->{$item}->{owners}->{$owner}) {
		delete $this->{cache}->{$item}->{owners}->{$owner};
		$this->{dirty}->{$item}=1;
	}
	unless (keys %{$this->{cache}->{$item}->{owners}}) {
		$this->{cache}->{$item}=undef;
		$this->{dirty}->{$item}=1;
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
	$this->{dirty}->{$item}=1;
	return $this->{cache}->{$item}->{fields}->{$field} = $value;	
}

=head2 removefield(itemname, fieldname)

Remove the field from the cache, if the underlying db is not readonly.

=cut

sub removefield {
	my $this=shift;
	my $item=shift;
	my $field=shift;

	return if $this->{readonly};
	return unless $this->cached($item);
	$this->{dirty}->{$item}=1;
	return delete $this->{cache}->{$item}->{fields}->{$field};
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
	return $this->{cache}->{$item}->{flags}->{$flag}
		if exists $this->{cache}->{$item}->{flags}->{$flag};
	return 'false';
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
	$this->{dirty}->{$item}=1;
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
	$this->{dirty}->{$item}=1;
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

Joey Hess <joeyh@debian.org>

=cut

1
