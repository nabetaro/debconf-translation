#!/usr/bin/perl -w
#
# Question object for Debian configuration database.

package Debian::DebConf::Question;
use strict;
use vars qw($AUTOLOAD);

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

# Fill in variables when returning description. This cannot actually
# be used to set the description, since the real description is on the
# template.
sub description {
	my $this=shift;
	return $this->_expand_vars($this->template->description);
}

# Fill in variables when returning extended description. This cannot actually
# be used to set the description, since the real description is on the
# template.
sub extended_description {
	my $this=shift;
	return $this->_expand_vars($this->template->extended_description);
}

# Access the variables hash. Pass in no parameters to get the full hash.
# Pass in one parameter to get the value of that hash key.
# Pass in two parameters to set a hash key to a value.
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

1
