#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver - base class for debconf db drivers

=cut

package Debconf::DbDriver;
use strict;

=head1 DESCRIPTION

This is a base class that may be inherited from by debconf database
drivers. It provides a simple interface that debconf uses to look up
information related to items in the database.

=cut

=head1 FIELDS

=over 4

=item readonly

Set to true if this database driver is read only.

=item required

Set to true if a database driver is required for proper operation of
debconf. Required drivers can cause debconf to abort if they are not
accessible. It can be useful to make remote databases non-required, so
debconf is usable if connections to them go down.

=back

=cut

# I rarely base objects on fields, but I want strong compile-time type
# checking for this class of objects, and speed.
use fields qw(readonly);

=head1 METHODS

=head2 new

Create a new object of this class. A hash of fields and values may be
passed in to set initial state.

=cut

sub new {
	my Debconf::DbDriver $this=shift;
	unless (ref $this) {
		$this = fields::new($this);
	}
	my %params=@_;
	foreach my $field (keys %params) {
		if ($field eq 'readonly' || $field eq 'required') {
			# Convert from true/false strings to numbers.
			$this->{$field}=1,next if lc($params{$field}) eq "true";
			$this->{$field}=1,next if lc($params{$field}) eq "false";
		}
		$this->{$field}=$params{$field};
	}
	$this->init;
	return $this;
}

=head2 init

Called when a new object of this class is instantiated. Override to
add initialization code.

=cut

sub init {}

=head2 error(message)

Rather than ever dying on errors, drivers should instead call
this method to state than an error was encountered. If the driver is
required, it will be a fatal error. If not, the error message will merely
be displayed to the user, and debconf will continue on, "dazed and
confuzed".

=cut

sub error {
	my $this=shift;

	if ($this->{required}) {
		die shift()."\n";
	}
	else {
		print STDERR shift()."\n";
	}
}

=head2 iterate([itarator])

Iterate over all available items. If called with no arguments, it returns
an itarator. If called with the iterator passed in, it returns the next
item in the sequence, or undef if there are no more.

=cut

sub iterate {}

=head2 savedb

Save the entire database state.

=cut

sub savedb {}

=head2 exists(itemname)

Return true if the given item exists in the database.

=cut

sub exists {}

=head2 addowner(itemname, ownername)

Register an owner for the given item. Returns the owner name, or undef
if this failed.

Note that adding an owner can cause a new item to spring into
existance.

=cut

sub addowner {}

=head2 removeowner(itemname, ownername)

Remove an owner from a item. Returns the owner name, or undef if
removal failed. If the number of owners goes to zero, the item should
be removed.

=cut

sub removeowner {}

=head2 owners(itemname)

Return a list of all owners of the item.

=cut

sub owners {}

=head2 getfield(itemname, fieldname)

Return the given field of the given item, or undef if getting that
field failed.

=cut

sub getfield {}

=head2 setfield(itemname, fieldname, value)

Set the given field the the given value, and return the value, or undef if
setting failed.

=cut

sub setfield {}

=head2 fields(itemname)

Return the fields present in the item.

=cut

sub fields {}

=head2 getflag(itemname, flagname)

Return 'true' if the given flag is set for the given item, "false" if
not.

=cut

sub getflag {}

=head2 setflag(itemname, flagname, value)

Set the given flag to the given value (will be one of "true" or "false"),
and return the value. Or return undef if setting failed.

=cut

sub setflag {}

=head2 flags(itenname)

Return the flags that are present for the item.

=cut

sub flags {}

=head2 getvariable(itemname, variablename)

Return the value of the given variable of the given item, or undef if
there is no such variable.

=cut

sub getvariable {}

=head2 setvariable(itemname, variablename, value)

Set the given variable of the given item to the value, and return the
value, or undef if setting failed.

=cut

sub setvariable {}

=head2 variables(itemname)

Return the variables that exist for the item.

=cut

sub variables {}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
