#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::Stack - stack of drivers

=cut

package Debconf::DbDriver::Stack;
use strict;
use Debconf::Log qw{:all};
use Debconf::Iterator;
use base 'Debconf::DbDriver';

=head1 DESCRIPTION

This sets up a stack of drivers. Items in drivers higher in the stack
shadow items lower in the stack, so requests for items will be passed on
to the first driver in the stack that contains the item.

Writing to the stack is more complex, because we meed to worry about
readonly drivers. Instead of trying to write to a readonly driver and
having it fail, this module will copy the item from the readonly driver
to the writable driver closest to the top of the stack that accepts the
given item, and then perform the write.

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

=head2 iterator

Iterates over all the items in all the drivers in the whole stack. However,
only return each item once, even if multiple drivers contain it.

=cut

sub iterator {
	my $this=shift;

	my %seen;
	my @iterators = map { $_->iterator } @{$this->{stack}};
	my $iterator=Debconf::Iterator->new(callback => sub {
		while (my $i = pop @iterators) {
			my $ret=$i->iterate;
			next unless defined $ret;
			next if $seen{$ret};
			$seen{$ret}=1;
			return $ret;
		}
		return undef;
	});
}

=head2 savedb

Calls savedb on the entire stack. If any savedb call returns undef, returns
undef too, but only after calling them all.

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
	
	debug "DbDriver $this->{name}" => "trying to $command ..";
	foreach my $driver (@{$this->{stack}}) {
		if (wantarray) {
			my @ret=$driver->$command(@_);
			debug "DbDriver $this->{name}" => "$command done by $driver->{name}" if @ret;
			return @ret if @ret;
		}
		else {
			my $ret=$driver->$command(@_);
			debug "DbDriver $this->{name}" => "$command done by $driver->{name}" if defined $ret;
			return $ret if defined $ret;
		}
	}
	return; # faulure
}

sub _change {
	my $this=shift;
	my $command=shift;
	shift; # this again
	my $item=shift;

	debug "DbDriver $this->{name}" => "trying to $command ..";

	# Check to see if we can just write to some driver in the stack.
	foreach my $driver (@{$this->{stack}}) {
		if ($driver->exists($item)) {
			last if $driver->{readonly}; # nope, hit a readonly one
			debug "DbDriver $this->{name}" => "passing to $driver->{name} ..";
			return $driver->$command($item, @_);
		}
	}

	# Set if we need to copy from something.
	my $src=0;

	# Find out what (readonly) driver on the stack first contains the item.
	foreach my $driver (@{$this->{stack}}) {
		if ($driver->exists($item)) {
			# Check if this modification would really have any
			# effect.
			my $ret=$this->_nochange($driver, $command, $item, @_);
			if (defined $ret) {
				debug "DbDriver $this->{name}" => "skipped $command($item) as it would have no effect";
				return $ret;
			}

			# Nope, we have to copy after all.
			$src=$driver;
			last
		}
	}

	# Work out what driver on the stack will be written to.
	# We'll take the first that accepts the item.
	my $writer;
	foreach my $driver (@{$this->{stack}}) {
		if ($driver == $src) {
			# Woah, mama!
			debug "DbDriver $this->{name}" =>
				"$src->{name} is readonly, and nothing above it in the stack will accept $item -- FAILURE";
			return;
		}
		if (! $driver->{readonly} and $driver->accept($item)) {
			$writer=$driver;
			last;
		}
	}
	
	unless ($writer) {
		debug "DbDriver $this->{name}" => "FAILED $command";
		return;
	}

	# Do the copy if we have to.
	if ($src) {		
		$this->_copy($item, $src, $writer);
	}

	# Finally, do the write.
	debug "DbDriver $this->{name}" => "passing to $writer->{name} ..";
	return $writer->$command($item, @_);
}

# This handles copying an item. The destination is assumed not to
# have the item yet.
sub _copy {
	my $this=shift;
	my $item=shift;
	my $src=shift;
	my $dest=shift;
	
	debug "DbDriver $this->{name}" => "copying $item from $src->{name} to $dest->{name}";
	
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
		@list=$driver->fields($item);
		$get='getfield';
	}
	elsif ($command eq 'setflag') {
		@list=$driver->flags($item);
		my $get='getflag';
	}
	elsif ($command eq 'setvariable') {
		@list=$driver->variables($item);
		my $get='getvariable';
	}
	else {
		$this->error("internal error; bad command: $command");
	}

	my $thing=shift;
	my $value=shift;
	my $currentvalue=$driver->$get($item, $thing);
	
	# If the thing doesn't exist yet, there will be a change.
	my $exists=0;
	foreach my $i (@list) {
		$exists=1, last if $thing eq $i;
	}
	return $currentvalue unless $exists;

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
sub variables	{ $_[0]->_query('variables', @_) }

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
