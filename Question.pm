#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Question - Question object

=cut

=head1 DESCRIPTION

This is an object that represents a Question. Each Question has some associated
data. To get at this data, just use $question->fieldname to read a field, and 
$question->fieldname(value) to write a field. Any field names at all can be used, 
the convention is to lower-case their names, and prefix the names of fields that
are flags with "flag_". If a field that is not defined is read, and a field by the
same name exists on the Template the Question is mapped to, the value of that field
will be returned instead.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Question;
use strict;
use vars qw($AUTOLOAD);

=head2 new

Returns a new Question object.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	$self->{flag_isdefault}='true';
	$self->{variables}={};
	bless ($self, $class);
	return $self;
}

# This is a helper function that expands variables in a string.
sub _expand_vars {
	my $this=shift;
	my $text=shift;
	
	my %vars=%{$this->variables};
	
	my $rest=$text;
	my $result='';
	while ($rest =~ m/^(.*?)\${([^{}]+)}(.*)$/sg) {
		$result.=$1;  # copy anything before the variable
		$result.=$vars{$2}; # expand the variable
		$rest=$3; # continue trying to expand rest of text
	}
	$result.=$rest; # add on anything that's left.
	
	return $result;
}

=head2 description

Returns the description of this Question. This value is taken from the Template
the Question is mapped to, and then any substitutions in the description are
expanded.

=cut

sub description {
	my $this=shift;
	return $this->_expand_vars($this->template->description);
}

=head2 description

Returns the extended description of this Question. This value is taken from the
Template the Question is mapped to, and then any substitutions in the extended
description are expanded.

=cut

sub extended_description {
	my $this=shift;
	return $this->_expand_vars($this->template->extended_description);
}

=head2 variables

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

# Set/get property.
sub AUTOLOAD {
	my $this=shift;
	my $property = $AUTOLOAD;
	$property =~ s|.*:||; # strip fully-qualified portion

	$this->{$property}=shift if @_;
	return $this->{$property} if (defined $this->{$property});
	return $this->{template}->$property();
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
