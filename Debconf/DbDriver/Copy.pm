#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::Copy - class that can make copies

=cut

package Debconf::DbDriver::Copy;
use strict;
use Debconf::Log qw{:all};
use base 'Debconf::DbDriver';

=head1 DESCRIPTION

This driver is not useful on its own, it is just the base of other classes
that need to be able to copy entire database items around.

=head1 METHODS

=item copy(item, src, dest)

Copies the given item from the source database to the destination database.
The item is assumed to not already exist in dest.

=cut

sub copy {
	my $this=shift;
	my $item=shift;
	my $src=shift;
	my $dest=shift;
	
	debug "db $this->{name}" => "copying $item from $src->{name} to $dest->{name}";
	
	# First copy the owners, which makes sure $dest has the item.
	my @owners=$src->owners($item);
	if (! @owners) {
		@owners=("unknown");
	}
	foreach my $owner (@owners) {
		my $template = Debconf::Template->get($src->getfield($item, 'template'));
		my $type="";
		$type = $template->type if $template;
		$dest->addowner($item, $owner, $type);
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

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
