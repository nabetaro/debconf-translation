#!/usr/bin/perl -w

=head1 NAME

Debconf::Question - Question object

=cut

package Debconf::Question;
use strict;
use Debconf::ConfigDb;
use vars qw($AUTOLOAD);
use base qw(Debconf::Base);
use Debconf::Log qw(:all);

=head1 DESCRIPTION

This is a an object that represents a Question. Each Question has some
associated data. To get at this data, just use $question->fieldname
to read a field, and  $question->fieldname(value) to write a field. Any
field names at all can be used, the convention is to lower-case their names,
and prefix the names of fields that are flags with "flag_". If a field that
is not defined is read, and a field by the same name exists on the Template
the Question is mapped to, the value of that field will be returned instead.

=head1 METHODS

=over 4

=item init

Sets a few defaults. New questions default to having their seen flag
set to "false".

=cut

sub init {
	my $this=shift;
	
	$this->flag_seen('false');
	$this->variables({});
}

# This is a helper function that expands variables in a string.
sub _expand_vars {
	my $this=shift;
	my $text=shift;
		
	return '' unless defined $text;

	my %vars=%{$this->variables};
	
	my $rest=$text;
	my $result='';
	while ($rest =~ m/^(.*?)\${([^{}]+)}(.*)$/sg) {
		$result.=$1;  # copy anything before the variable
		$result.=$vars{$2} if defined($vars{$2}); # expand the variable
		$rest=$3; # continue trying to expand rest of text
	}
	$result.=$rest; # add on anything that's left.
	
	return $result;
}

=item description

Returns the description of this Question. This value is taken from the Template
the Question is mapped to, and then any substitutions in the description are
expanded.

=cut

sub description {
	my $this=shift;
	return $this->_expand_vars($this->template->description);
}

=item extended_description

Returns the extended description of this Question. This value is taken from the
Template the Question is mapped to, and then any substitutions in the extended
description are expanded.

=cut

sub extended_description {
	my $this=shift;
	return $this->_expand_vars($this->template->extended_description);
}

=item choices

Returns the choices field of this Question. This value is taken from the
Template the Question is mapped to, and then any substitutions in it
are expanded.

=cut

sub choices {
	my $this=shift;
	
	return $this->_expand_vars($this->template->choices);
}

=item choices_split

This takes the result of the choices method and simply splits it up into
individual choices and returns them as a list.

=cut

sub choices_split {
	my $this=shift;
	
	return split(/,\s+/, $this->choices);
}

=item flag_isdefault

This deprecated flag is now automatically mapped to the inverse of the
"seen" flag.

=cut

sub flag_isdefault {
	my $this=shift;

	debug developer => "The isdefault flag is deprecated, use the seen flag instead";

	$this->flag_seen(shift() eq "true" ? "false" : "true") if @_;
	return $this->flag_seen eq "true" ? "false" : "true";
}

=item variables

Access the variables hash, which is a hash of values that are used in the above
substitutions. Pass in no parameters to get the full hash. 
Pass in one parameter to get the value of that hash key. Pass in two parameters
to set a hash key to a value.

=cut

sub variables {
	my $this=shift;
	
	if (@_ == 0) {
		return $this->{variables};
	} elsif (@_ == 1) {
		my $varname=shift;
		return $this->{variables}{$varname};
	} else {
		my $varname=shift;
		my $varval=shift;
		return $this->{variables}{$varname} = $varval;
	}
}	

=item value

Get the current value of this Question. Will return the default value is there
is no value set. Pass in a value to set the value.

=cut

sub value {
	my $this = shift;
	
	if (@_ == 0) {
		return $this->{value} if (defined $this->{value});
		return $this->template->default if ref $this->template;
	} else {
		return $this->{value} = shift;
	}
}

=item value_split

This takes the result of the value method and simply splits it up into
individual values and returns them as a list.

=cut

sub value_split {
	my $this=shift;
	
	my $value=$this->value;
	$value='' if ! defined $value;
	return split(/,\s+/, $value);
}

=item owners

This method allows you to get/set the owners of a Question. The owners are
returned in a comma and space delimited list, a similar list should be
passed in if you wish to use this function to set them. (Internally, the
owners are stored quite differently..)

=cut

sub owners {
	my $this=shift;
	
	if (@_) {
		# Generate hash on fly.
		my %owners=map { $_, 1 } split(/,\s*/, shift);
		$this->{'owners'}=\%owners;
	}
	
	if ($this->{'owners'}) {
		return join(", ", keys %{$this->{'owners'}});
	}
	else {
		return "";
	}
}

=item addowner

Add an owner to the list of owners of this Question. Pass the owner name.
Adding an owner that is already listed has no effect.

=cut

sub addowner {
	my $this=shift;
	my $owner=shift;

	# I must be careful to access the real hash, bypassing the 
	# method that stringifiys the owners field.
	my %owners;
	if ($this->{'owners'}) {
		%owners=%{$this->{'owners'}};
	}
	$owners{$owner}=1;
	$this->{'owners'}=\%owners;
}

=item removeowner

Remove an owner from the list of owners of this Question. Pass the owner name
to remove.

=cut

sub removeowner {
	my $this=shift;
	my $owner=shift;
	
	# I must be careful to access the real hash, bypassing the
	# method that stringifiys the owners field.
	my %owners;
	if ($this->{'owners'}) {
		%owners=%{$this->{'owners'}};
	}
	delete $owners{$owner};
	$this->{'owners'}=\%owners;
}

=item AUTLOAD

Handles all fields, by creating accessor methods for them the first time
they are accessed. Fields are first looked for in this object, and failing
that, the associated Template is queried for fields.

=cut

sub AUTOLOAD {
	my $field;
	($field = $AUTOLOAD) =~ s/.*://;

	no strict 'refs';
	*$AUTOLOAD = sub {
		my $this=shift;

		$this->{$field}=shift if @_;
		return $this->{$field} if (defined $this->{$field});
		# Fall back to template values.
		return $this->{template}->$field() if ref $this->{template};
	};
	goto &$AUTOLOAD;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
