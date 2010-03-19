#!/usr/bin/perl -w

=head1 NAME

Debconf::Template::Transient - Transient template object

=cut

package Debconf::Template::Transient;
use strict;
use base 'Debconf::Template';
use fields qw(_fields);

=head1 DESCRIPTION

This class provides Template objects that are not backed by a persistent
database store. It is useful for situations where transient operations
needs to be performed on templates. Note that unlike regular templates,
multiple transient templates may exist with the same name.

=cut

=head1 CLASS METHODS

=item new(template)

The name of the template to create must be passed to this function.

=cut

sub new {
	my $this=shift;
	my $template=shift;
	
	unless (ref $this) {
		$this = fields::new($this);
	}
	$this->{template}=$template;
	$this->{_fields}={};
	return $this;
}

=head2 get

This method is not supported by this function. Multiple transient templates
with the same name can exist.

=cut

sub get {
	die "get not supported on transient templates";
}

=head2 fields

Returns a list of all fields that are present in the object.

=cut

sub fields {
	my $this=shift;

	return keys %{$this->{_fields}};
}

=head2 clearall

Clears all the fields of the object.
                
=cut
                
sub clearall {
	my $this=shift;

	foreach my $field (keys %{$this->{_fields}}) {
		delete $this->{_fields}->{$field};
	}
}

=head2 AUTOLOAD

Creates and calls accessor methods to handle fields. 
This supports internationalization.

=cut

{
	my @langs=Debconf::Template::_getlangs();

	sub AUTOLOAD {
		(my $field = our $AUTOLOAD) =~ s/.*://;
		no strict 'refs';
		*$AUTOLOAD = sub {
			my $this=shift;

			return $this->{_fields}->{$field}=shift if @_;
		
			# Check to see if i18n should be used.
			if ($Debconf::Template::i18n && @langs) {
				foreach my $lang (@langs) {
					# Lower-case language name because
					# fields are stored in lower case.
					return $this->{_fields}->{$field.'-'.lc($lang)}
						if exists $this->{_fields}->{$field.'-'.lc($lang)};
				}
			}
			return $this->{_fields}->{$field};
		};
		goto &$AUTOLOAD;
	}
}

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
