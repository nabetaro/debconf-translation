#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::Stack - stack of drivers

=cut

package Debconf::DbDriver::Stack;
use strict;
use base 'Debconf::DbDriver';

=head1 DESCRIPTION

This sets up a stack of drivers. Items in drivers higher in the stack
shadow items lower in the stack, so requests for items will be passed on
to the first driver in the stack that contains the item.

Writing to the stack is more complex, because we meed to worry about
readonly drivers. Instead of trying to write to a readonly driver and
having it fail, this module will copy the item from the readonly driver
to driver at the top of the stack, and then perform the write to the topmost
driver.

=cut

=head1 FIELDS

=over 4

=item stack

A reference to an array of drivers. The topmost driver should not be
readonly.

In the config file, a comma-delimeted list of driver names can be specified
for this field.

=back

=cut

use fields qw(stack);

=head1 METHODS

=head2 init

On initialization, the topmost driver is checked for writability.

=cut

sub init {
	my $this=shift;

	# Handle value from config file.
	if (! ref $this->{stack}) {
		my @stack;
		foreach my $name (split(/\s*,\s/, $this->{stack})) {
			my $driver=$this->driver($name);
			unless (defined $driver) {
				$this->error("could not find a driver named \"$name\" to use in the stack (it should be defined before the stack in the config file)");
				next;
			}
			push @stack, $driver;
		}
		$this->{stack}=[@stack];
	}

	$this->error("no stack set") if ! ref $this->{stack};
	$this->error("stack is empty") if ! @{$this->{stack}};
	$this->error("topmost driver not writable")
		if $this->{stack}->[0]->{readonly};
}

=head2 iterate

Iterates over all the items in all the drivers in the whole stack. However,
only return each item twice, even if multiple drivers contain it.

=cut

sub iterate {
	my $this=shift;
	my $iterator=shift;

	if (not $iterator) {	
		# Use a reference to a list as the iterator.
		# The list is composed of pairs of items. The first item in
		# a pair is the db driver, while the second is the
		# iterator. A final item is tacked on the back of the list;
		# this is a hash reference; the hash lists items that
		# the iterator has already seen.
		$iterator=[(map { $_ => $_->iterate } @{$this->{stack}}), {} ];
	}

	# Iterate the first thing in our list.
	my $ret;
	do {
		$ret=$iterator->[0]->iterate($iterator->[1]);
		if (defined $ret and ! $iterator->[-1]->{$ret}) {
			# Well this is new.
			$iterator->[-1]->{$ret}=1;
			return $ret;
		}
	} while defined $ret;
	
	# If we got to here, an item is done, so remove it and its iterator
	# from the list, and move on to the next.
	shift @{$iterator};
	shift @{$iterator};
	return if @{$iterator} == 1; # all done
	return $this->iterate($iterator); # look, ma! useless tail recursion!
}

=head2 savedb

Calls savedb on the entire stack. If any savedb call returns undef, returns
undef, but only after calling them all.

=cut

sub savedb {
	my $this=shift;

	my $ret=1;
	foreach my $driver (@{$this->{stack}}) {
		$ret=undef if not defined $driver->savedb(@_);
	}
	return $ret;
}

# From here on out, the methods are of two types, as explained in
# the description above. Either we query the stack, or we make a
# change to a writable item, copying an item from lower in the stack first
# as is necessary.
sub _query {
	my $this=shift;
	my $command=shift;
	shift; # this again
	
	foreach my $driver (@{$this->{stack}}) {
		my $ret=$driver->$command(@_);
		return $ret if defined $ret;
	}
	return undef; # all failed
}

sub _change {
	my $this=shift;
	my $command=shift;
	shift; # this again
	my $item=shift;

	# Check to see if we can just write to some driver in the stack.
	foreach my $driver (@{$this->{stack}}) {
		last if $driver->{readonly};
		if ($driver->exists($item)) {
			return $driver->$command($item, @_);
		}
	}

	# Find out what (readonly) driver on the stack first
	# contains the item, and do the copy to the top of the stack.
	foreach my $driver (@{$this->{stack}}) {
		if ($driver->exists($item)) {
			my $ret=$this->_nochange($driver, $command, $item, @_);
			return $ret if defined $ret;
			
			# Nope, we have to copy after all.
			_copy($item, $driver, $this->{stack}->[0]);
			last;
		}
	}

	# Finally, do the write to the top of the stack.
	return $this->{stack}->[0]->$command($item, @_);
}

# This handles copying an item. The destination is assumed not to
# have the item yet.
sub _copy {
	my $item=shift;
	my $src=shift;
	my $dest=shift;
	
	# First copy the owners, which makes sure $dest has the item.
	foreach my $owner ($src->owners($item)) {
		$dest->addowner($item, $owner);
	}
	# Now the fields.
	foreach my $field ($src->fields($item)) {
		$dest->setfield($item, $field, $src->getfield($item, $field));
	}
	# Now the flags.
	foreach my $flag ($src->flags($item)) {
		$dest->setflag($item, $flag, $src->getflag($item, $flag));
	}
	# And finally the variables.
	foreach my $var ($src->variables($item)) {
		$dest->setvariable($item, $var, $src->getvariable($item, $var));
	}
}

# A problem occurs sometimes: A write might be attempted that will not
# actually change the database at all. If we naively copy an item up the
# stack in these cases, we have shadowed the real data unnecessarily. 
# Instead, I bothered to add a shitload of extra intelligence, to detect
# such null writes, and do nothing but return whatever the current value is.
# Gar gar gar!
sub _nochange {
	my $this=shift;
	my $driver=shift;
	my $command=shift;
	my $item=shift;

	if ($command eq 'addowner') {
		my $value=shift;

		# If the owner is already there, no change.
		foreach my $owner ($driver->owners($item)) {
			return $value if $owner eq $value;
		}
		return;
	}
	elsif ($command eq 'removeowner') {
		my $value=shift;
		
		# If the owner is already in the list, there is a change.
		foreach my $owner ($driver->owners($item)) {
			return if $owner eq $value;
		}
		return $value; # no change
	}

	# Ok, the rest is close to the same for fields, flags, and variables.
	my @list;
	my $get;
	if ($command eq 'setfield') {
		@list=$driver->fields;
		$get='getfield';
	}
	elsif ($command eq 'setflag') {
		@list=$driver->flags;
		my $get='getflag';
	}
	elsif ($command eq 'setvariable') {
		@list=$driver->variables;
		my $get='getvariable';
	}
	else {
		$this->error("internal error; bad command: $command");
	}

	my $thing=shift;
	my $value=shift;
	my $currentvalue=$driver->$get($item, $thing);

	# If the thing doesn't exist yet, there will be a change.
	foreach my $i (@list) {
		return $currentvalue if $thing eq $i;
	}
	# If the thing does not have the same value, there will be a change.
	return $currentvalue if $currentvalue eq $value;
	return undef;
}

sub exists	{ $_[0]->_query('exists', @_) }
sub addowner	{ $_[0]->_change('addowner', @_) }
# Note that if the last owner of an item is removed, it next item
# down in the stack is unshadowed and becomes active. May not be
# the right behavior.
sub removeowner { $_[0]->_change('removeowner', @_) }
sub owners	{ $_[0]->_query('owners', @_) }
sub getfield	{ $_[0]->_query('getfield', @_) }
sub setfield	{ $_[0]->_change('setfield', @_) }
sub fields	{ $_[0]->_query('fields', @_) }
sub getflag	{ $_[0]->_query('getflag', @_) }
sub setflag	{ $_[0]->_change('setflag', @_) }
sub flags	{ $_[0]->_query('flags', @_) }
sub getvariable { $_[0]->_query('getvariable', @_) }
sub setvariable { $_[0]->_change('setvariable', @_) }
sub variables	{ $_[0]->_query('vaiables', @_) }

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
