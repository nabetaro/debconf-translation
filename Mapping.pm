#!/usr/bin/perl -w
#
# Mapping object for Debian configuration management system.

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

# Helper for parse, sets a field to a value.
sub _savefield {
	my $this=shift;
	my $field=shift;
	my $value=shift;

	$this->$field($value) if $field ne '';
}

# This method parses a string containing a mapping and stores all the
# information in the mapping object.
sub parse {
	my $this=shift;
	my $text=shift;

	my ($field, $value)=('', '');
	foreach (split "\n", $text) {
		chomp;
		if (/^([-A-Za-z0-9]*): (.*)/) {
			# New item.
			$this->_savefield($field, $value);
			$field=lc $1;
			$value=$2;
		}
		else {
			die "Mapping parse error near \"$_\"";
		}
	}
	$this->_savefield($field, $value);

	# Sanity checks.
	die "Mapping does not contain a Question: line" unless $this->{question};
}

# Set/get property.
sub AUTOLOAD {
	my $this=shift;
	my $property = $AUTOLOAD;
	$property =~ s|.*:||; # strip fully-qualified portion
	
	$this->{$property}=shift if @_;
	$this->{$property};
}

1
