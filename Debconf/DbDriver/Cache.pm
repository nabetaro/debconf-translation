#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::Cache - caching database driver

=cut

package Debconf::DbDriver::Cache;
use strict;
use base qw(Debconf::DbDriver);

=head1 DESCRIPTION

This is a debconf database driver that layers over top of another driver,
accessing it as little as possible, and caching data in memory.

This driver can be layered over any database driver that is derived from
Debconf::DbDriver::Cacheable.

=head1 FIELDS

=over 4

=item cache

A reference to a hash that holds the data for each loaded item in the
database. Each hash key is a item name; hash values are either undef
(used to indicate that a item used to exist here, but was deleted), or
are themselves references to hashes that hold the item data.

=item db

A Debconf::Db object, this is the real database driver the cache is layered
over. Requests will be passed on to it as necessary. This object should be
passed in on object creation.

=back

=head1 METHODS

=head2 init

On initialization, the cache is empty. A db must exist, and it must be
cacheable, or we abort.

=cut

sub init {
	my $this=shift;

	die "No database specified" unless $this->db;
	die "Underlying database not cachable"
		unless UNIVERSAL::isa($this->db, "Debconf::DbDriver::Cacheable");

	$this->cache({});
}

=head2 iterate([iterator])

Since we don't know the full set of available items, we pass
this on entirely to the underlying db driver.

=cut

sub iterate {
	my $this=shift;
	$this->db->iterate(@_);
}

=cut

=head2 load(itemname)

Load a item up from the underlying db if it is not already in the
cache.

=cut

sub load {
	my $this=shift;
	my $item=shift;

	if (! exists $this->cache->{$item}) {
		# Try to load it up from the underlying db.
		$this->cache->{$item}=$this->db->load($item);
	}
	return $this->cache->{$item};
}

=head2 save(itemname)

Saving a item involves feeding the item from the cache 
into the underlying database, and then telling the underlying db to save
it.

However, if the item is undefined in the cache, we instead tell the
underlying db to delete it.

=cut

sub save {
	my $this=shift;
	my $item=shift;
	my $value=shift;
	
	return if $this->db->readonly;
	if (! exists $this->cache->{$item}) {
		# We never touched this item, so don't bother trying to
		# save it. However, if it doesn't exist in the underlying
		# db, trying to save it is certianly an error.
		return not $this->db->exists($item);
	}
	
	if (defined $this->cache->{$item}) {
		return $this->db->save($item, $this->cache->{$item});
	}
	else {
		return $this->db->remove($item);
	}
}

=head2 exists(itemname)

Return true if the item exists in the cache or database.

=cut

sub exists {
	my $this=shift;
	my $item=shift;
	
	return 1 if defined $this->cache->{$item};
	return 0 if exists $this->cache->{$item}; # item marked as removed
	# Otherwise, forward the request to the real database driver.
	return $this->db->exists($item);
}

=head2 remove(itemname)

Mark the item as removed in the cache.

=cut

sub remove {
	my $this=shift;
	my $item=shift;

	return if $this->db->readonly;

	$this->cache->{$item}=undef;
}

=head2 addowner(itemname, ownername)

Add an owner, if the underlying db is not readonly.

=cut

sub addowner {
	my $this=shift;
	my $item=shift;
	my $owner=shift;

	return if $this->db->readonly;
	$this->load($item);

	if (! defined $this->cache->{$item}) {
		# The item springs into existance.
		$this->cache->{$item}={
			owners => {},
			fields => {},
			variables => {},
			flags => {},
		}
	}

	$this->cache->{$item}->{owners}->{$owner}=1;
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

	return if $this->db->readonly;
	return unless $this->load($item);

	delete $this->cache->{$item}->{owners}->{$owner};
	unless (keys %{$this->cache->{$item}->{owners}}) {
		$this->remove($item);
	}
	return $owner;
}

=head2 getfield(itemname, fieldname)

Pulls the field out of the cache.

=cut

sub getfield {
	my $this=shift;
	my $item=shift;
	my $field=shift;

	return unless $this->load($item);
	return $this->cache->{$item}->{fields}->{$field};
}

=head2 setfield(itemname, fieldname, value)

Set the field in the cache, if the underlying db is not readonly.

=cut

sub setfield {
	my $this=shift;
	my $item=shift;
	my $field=shift;
	my $value=shift;

	return if $this->db->readonly;
	return unless $this->load($item);
	return $this->cache->{$item}->{fields}->{$field} = $value;	
}

=head2 fields(itemname)

Pulls the field list out of the cache.

=cut

sub fields {
	my $this=shift;
	my $item=shift;
	
	return unless $this->load($item);
	return keys %{$this->cache->{$item}->{fields}};
}

=head2 getflag(itemname, flagname)

Pulls the flag out of the cache.

=cut

sub getflag {
	my $this=shift;
	my $item=shift;
	my $flag=shift;
	
	return unless $this->load($item);
	return $this->cache->{$item}->{flags}->{$flag};
}

=head2 setflag(itemname, flagname, value)

Sets the flag in the cache, if the underlying db is not readonly.

=cut

sub setflag {
	my $this=shift;
	my $item=shift;
	my $flag=shift;
	my $value=shift;

	return if $this->db->readonly;
	return unless $this->load($item);
	return $this->cache->{$item}->{flags}->{$flag} = $value;
}

=head2 flags(itemname)

Pulls the flag list out of the cache.

=cut

sub flags {
	my $this=shift;
	my $item=shift;

	return unless $this->load($item);
	return keys %{$this->cache->{$item}->{flags}};
}

=head2 getvariable(itemname, variablename)

Pulls the variable out of the cache.

=cut

sub getvariable {
	my $this=shift;
	my $item=shift;
	my $variable=shift;

	return unless $this->load($item);
	return $this->cache->{$item}->{variables}->{$variable};
}

=head2 setvariable(itemname, variablename, value)

Sets the flag in the cache, if the underlying db is not readonly.

=cut

sub setvariable {
	my $this=shift;
	my $item=shift;
	my $variable=shift;
	my $value=shift;

	return if $this->db->readonly;
	return unless $this->load($item);
	return $this->cache->{$item}->{variables}->{$variable} = $value;
}

=head2 variables(itemname)

Pulls the variable list out of the cache.

=cut

sub variables {
	my $this=shift;
	my $item=shift;

	return unless $this->load($item);
	return keys %{$this->cache->{$item}->{variables}};
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
