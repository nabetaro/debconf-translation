#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::Cacheable - cachable database driver

=cut

package Debconf::DbDriver::Cacheable;
use strict;
use base qw(Debconf::DbDriver);

=head1 DESCRIPTION

This is a base class for debconf database drivers that are cachable by
Debconf::DbDriver::Cache. Use this as the base class for your driver if
it makes sense to load and store items as a whole (eg, if you are using
text files to reprosent each item, or downloading whole items over
the net), and you don't want to bother implementing anything except the three
emthods below.

Don't use this base class for your driver if it makes more sense for your
driver to access individual parts of each item independantly (by
querying a database, for example).

=head1 METHODS

The methods described below must be implemented. All other methods
Debconf::DbDrivers may have are optional if the object is always overlaid
by a cache (the cache only uses the methods described below). If it is not
always so overlaid, they should be implemented as well.

=head2 load(itemname)

When a database item is loaded, cacheable drivers must really load up the
entire item. Then they must return a rather complex hashed structure to
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

=head2 save(itemname,[value])

If the object is overlaid by a cache, this method will be passed a an identical
hash structure as described above, and that is what should be saved.

=head2 exists(itemname)

Return true if the given item exists in the database.

=head2 remove(itemame)

Remove a item from the database.

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
