#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver - base class for debconf db drivers

=cut

package Debconf::DbDriver;
use Debconf::Log qw{:all};
use strict;
use base 1.01; # ensure that they don't have a broken perl installation

=head1 DESCRIPTION

This is a base class that may be inherited from by debconf database
drivers. It provides a simple interface that debconf uses to look up
information related to items in the database.

=cut

=head1 FIELDS

=over 4

=item name

The name of the database. This field is required.

=item readonly

Set to true if this database driver is read only. Defaults to false.

In the config file the literal strings "true" and "false" can be used.
Internally it uses 1 and 0.

=item backup

Detemrines whether a backup should be made of the old version of the
database or not.

In the config file the literal strings "true" and "false" can be used.
Internally it uses 1 and 0.

=item required

Tells if a database driver is required for proper operation of
debconf. Required drivers can cause debconf to abort if they are not
accessible. It can be useful to make remote databases non-required, so
debconf is usable if connections to them go down. Defaults to true.

In the config file the literal strings "true" and "false" can be used.
Internally it uses 1 and 0.

=item failed

Tells if a database driver failed to work. If this is set the driver should
begin to reject all requests.

=item accept_type

A regular expression indicating types of items that may be queried in this
driver. Defaults to accepting all types of items.

=item reject_type

A regular expression indicating types of items that are rejected by this
driver.

=item accept_name

A regular expression that is matched against item names to see if they are
accepted by this driver. Defaults to accepting all item names.

=item reject_name

A regular expression that is matched against item names to see if they are
rejected by this driver.

=back

=cut

# I rarely base objects on fields, but I want strong compile-time type
# checking for this class of objects, and speed.
use fields qw(name readonly required backup failed
              accept_type reject_type accept_name reject_name);

# Class data.
our %drivers;

=head1 METHODS

=head2 new

Create a new object. A hash of fields and values may be passed in to set
initial state. (And you have to use this to set the name, at the very
least.)

=cut

sub new {
	my Debconf::DbDriver $this=shift;
	unless (ref $this) {
		$this = fields::new($this);
	}
	# Set defaults.
	$this->{required}=1;
	$this->{readonly}=0;
	$this->{failed}=0;
	# Set fields from parameters.
	my %params=@_;
	foreach my $field (keys %params) {
		if ($field eq 'readonly' || $field eq 'required' || $field eq 'backup') {
			# Convert from true/false strings to numbers.
			$this->{$field}=1,next if lc($params{$field}) eq "true";
			$this->{$field}=0,next if lc($params{$field}) eq "false";
		}
		elsif ($field=~/^(accept|reject)_/) {
			# Internally, store these as pre-compiled regexps.
			$this->{$field}=qr/$params{$field}/i;
		}
		$this->{$field}=$params{$field};
	}
	# Name is a required field.
	unless (exists $this->{name}) {
		# Set to something since error function uses this field..
		$this->{name}="(unknown)";
		$this->error("no name specified");
	}
	# Register in class data.
	$drivers{$this->{name}} = $this;
	# Other initialization.
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
be displayed to the user, the driver will be marked as failed, and debconf
will continue on, "dazed and confuzed".

=cut

sub error {
	my $this=shift;

	if ($this->{required}) {
		warn('DbDriver "'.$this->{name}.'":', @_);
		exit 1;
	}
	else {
		warn('DbDriver "'.$this->{name}.'" warning:', @_);
	}
}

=head2 driver(drivername)

This is a class method that allows any driver to be looked up by name.
If any driver with the given name exists, it is returned.

=cut

sub driver {
	my $this=shift;
	my $name=shift;
	
	return $drivers{$name};
}

=head2 accept(itemname, [type])

Return true if this driver will accept queries for the given item. Uses the
various accept_* and reject_* fields to determine this.

The type field should be passed when possible, giving the type of the item.
If it is not passed, the function will try to look up the type in the item's
template, but that may not always work, if the template is not yet set up.

=cut

sub accept {
	my $this=shift;
	my $name=shift;
	my $type=shift;
	
	return if $this->{failed};
	
	if ((exists $this->{accept_name} && $name !~ /$this->{accept_name}/) ||
	    (exists $this->{reject_name} && $name =~ /$this->{reject_name}/)) {
		debug "db $this->{name}" => "reject $name";
		return;
	}

	if (exists $this->{accept_type} || exists $this->{reject_type}) {
		if (! defined $type || ! length $type) {
			my $template = Debconf::Template->get($this->getfield($name, 'template'));
			return 1 unless $template; # no type to act on
			$type=$template->type || '';
		}
		return if exists $this->{accept_type} && $type !~ /$this->{accept_type}/;
		return if exists $this->{reject_type} && $type =~ /$this->{reject_type}/;
	}

	return 1;
}

=head2 ispassword(itemname)

Returns true if the item appears to hold a password. This is pretty messy;
we have to dig up its template (unless it _is_ a template).

=cut

sub ispassword {
	my $this=shift;
	my $item=shift;

	my $template=$this->getfield($item, 'template');
	return unless defined $template;
	$template=Debconf::Template->get($template);
	return unless $template;
	my $type=$template->type || '';
	return 1 if $type eq 'password';
	return 0;
}

=head1 ABSTRACT METHODS

Subclasses must implement these methods.

=head2 iterator

Create an object of type Debconf::Iterator that can be used to iterate over
each item in the db, and return it.

Each subclass must implement this method.

=head2 shutdown

Save the entire database state, and closes down the driver's access to the
database.

Each subclass must implement this method.

=head2 exists(itemname)

Return true if the given item exists in the database.

Each subclass must implement this method.

=head2 addowner(itemname, ownername, type)

Register an owner for the given item. Returns the owner name, or undef
if this failed.

Note that adding an owner can cause a new item to spring into
existance.

The type field is used to tell the DbDriver what type of item is
being added (the DbDriver may decide to reject some types of items).

Each subclass must implement this method.

=head2 removeowner(itemname, ownername)

Remove an owner from a item. Returns the owner name, or undef if
removal failed. If the number of owners goes to zero, the item should
be removed.

Each subclass must implement this method.

=head2 owners(itemname)

Return a list of all owners of the item.

Each subclass must implement this method.

=head2 getfield(itemname, fieldname)

Return the given field of the given item, or undef if getting that
field failed.

Each subclass must implement this method.

=head2 setfield(itemname, fieldname, value)

Set the given field the the given value, and return the value, or undef if
setting failed.

Each subclass must implement this method.

=head2 removefield(itemname, fieldname)

Remove the given field from the given item, if it exists. This is _not_ the
same as setting the field to '', instead, it removes it from the list of
fields. Returns true unless removing of the field failed, when it will
return undef.

=head2 fields(itemname)

Return the fields present in the item.

Each subclass must implement this method.

=head2 getflag(itemname, flagname)

Return 'true' if the given flag is set for the given item, "false" if
not.

Each subclass must implement this method.

=head2 setflag(itemname, flagname, value)

Set the given flag to the given value (will be one of "true" or "false"),
and return the value. Or return undef if setting failed.

Each subclass must implement this method.

=head2 flags(itenname)

Return the flags that are present for the item.

Each subclass must implement this method.

=head2 getvariable(itemname, variablename)

Return the value of the given variable of the given item, or undef if
there is no such variable.

Each subclass must implement this method.

=head2 setvariable(itemname, variablename, value)

Set the given variable of the given item to the value, and return the
value, or undef if setting failed.

Each subclass must implement this method.

=head2 variables(itemname)

Return the variables that exist for the item.

Each subclass must implement this method.

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
