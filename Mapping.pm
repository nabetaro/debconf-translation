#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Mapping - Template to Question mapping object

=cut

=head1 DESCRIPTION

This is an object that represents a mapping between a Question and a Template.

Set the template property to the name of the template the Question is mapped to. Set
the question property to the name of the Question.

=cut

package Debian::DebConf::Mapping;
use strict;
use vars qw($AUTOLOAD);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	bless ($self, $class);
	return $self;
}

=head2 owner

This method allows you to get/set the owners of a mapping. The owners are
returned in a comma and space delimited list, a similar list should be passed
in if you wish to use this function to set them. (Internally, the owners are
stored quite differently..)

=cut

sub owner {
	my $this=shift;

	if (@_) {
		# Generate hash on fly.
		my %owners=map { $_, 1 } split(/,\s*/, shift);
		$this->{owners}=\%owners;
	}

	if ($this->{owners}) {
		return join(", ", keys %{$this->{owners}});
	}
	else {
		return "";
	}
}

=head2 addowner

Add an owner to the list of owners of this template. Pass the owner name.
Adding an owner that is already listed has no effect.

=cut

sub addowner {
	my $this=shift;
	my $owner=shift;

	# I must be careful to access the real hash, bypassing the 
	# method that stringifiys the owners property.
	my %owners;
	if (exists $this->{owners}) {
		%owners=%{$this->{owners}};
	}
	$owners{$owner}=1;
	$this->{owners}=\%owners;
}

=head2 removeowner

Remove an owner from the list of owners of this template. Pass the owner name
to remove.

=cut

sub removeowner {
	my $this=shift;
	my $owner=shift;
	
	# I must be careful to access the real hash, bypassing the
	# method that stringifiys the owners property.
	my %owners;
	if (exists $this->{owners}) {
		%owners=%{$this->{owners}};
	}
	delete $owners{$owner};
	$this->{owners}=\%owners;
}

# Set/get property.
sub AUTOLOAD {
	my $this=shift;
	my $property = $AUTOLOAD;
	$property =~ s|.*:||; # strip fully-qualified portion
	
	$this->{$property}=shift if @_;
	$this->{$property};
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
