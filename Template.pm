#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Template - Template object

=cut

=head1 DESCRIPTION

This is an object that represents a Template. Each Template has some associated
data, the fields of the template structure. To get at this data, just use
$template->fieldname to read a field, and $template->fieldname(value) to write
a field. Any field names at all can be used, the convention is to lower-case
their names. All Templates should have a "template" field that is their name.
Most have "default", "type", and "description" fields as well. The field
named "extended_description" holds the extended description, if any.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Template;
use strict;
use vars qw($AUTOLOAD);

=head2 new

Returns a new Template object.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	bless ($self, $class);
	return $self;
}

# Helper for parse, sets a field to a value.
sub _savefield {
	my $this=shift;
	my $field=shift;
	my $value=shift;
	my $extended=shift;

	if ($field eq 'description') {
		# Save short and long descs separatly.
		$this->description($value);
		$this->extended_description($extended);
	}
	elsif ($field eq 'choices') {
		# Split values at commas.
		$this->$field([split(/,\s*/, $value)]);
	}
	elsif ($field ne '') {
		$this->$field($value);
	}
}

=head2 merge

Pass this another Template and all properties of the object you
call this method on will be copied over onto the other Template
and any old values in the other Template will be removed.
(With the exception of the owners property.)

=cut

sub merge {
	my $this=shift;
	my $other=shift;

	# Breaking the abstraction just a little..
	foreach my $key (keys %$other) {
		next if $key eq 'owners';
		delete $other->{$key};
	}

	foreach my $key (keys %$this) {
		next if $key eq 'owners';
		$other->$key($this->{$key});
	}
}

=head2 parse

This method parses a string containing a template and stores all the
information in the Template object.

=cut

sub parse {
	my $this=shift;
	my $text=shift;

	my ($field, $value, $extended)=('', '', '');
	foreach (split "\n", $text) {
		chomp;
		if (/^([-A-Za-z0-9]*): (.*)/) {
			# Beginning of new item.
			$this->_savefield($field, $value, $extended);
			$field=lc $1;
			$value=$2;
			$extended='';
		}
		elsif (/^\s+\.$/) {
			# Continuation of item that contains only a blank line.
			$extended.="\n\n";
		}
		elsif (/^\s+(.*)/) {
			# Continuation of item.
			$extended.=$1." ";
		}
		else {
			die "Template parse error near \"$_\"";
		}
	}

	$this->_savefield($field, $value, $extended);

	# Sanity checks.
	die "Template does not contain a Template: line" unless $this->{template};
}

=head2 owner

This method allows you to get/set the owners of a template. The owners are returned 
in a comma and space delimited list, a similar list should be passed in if you wish to
use this function to set them. (Internally, the owners are stored quite differently..)

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
	if ($this->{owners}) {
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
	if ($this->{owners}) {
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
