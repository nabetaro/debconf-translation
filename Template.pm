#!/usr/bin/perl -w
#
# Template object for Debian configuration management system.

package Debian::DebConf::Template;
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
	my $extended=shift;

	if ($field eq 'description') {
		# Save short and long descs separatly.
		$this->description($value);
		$this->extended_description($extended);
	}
	elsif ($field eq 'choices') {
		# Split values at commas.
		$value=~s/\s+/ /;
		$this->$field([split(/, ?/, $value)]);
	}
	elsif ($field ne '') {
		$this->$field($value);
	}
}

# This method parses a string containing a template and stores all the
# information in the template object.
sub parse {
	my $this=shift;
	my $text=shift;

	my ($field, $value, $extended)=('', '', '');
	foreach (split "\n", $text) {
		chomp;
		if (/^([-A-Za-z0-9]*): (.*)/) {
			# Beginning of new item.
			$this->_savefield($field, $value);
			$field=lc $1;
			$value=$2;
		}
		elsif (/^\s+\./) {
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

# Set/get property.
sub AUTOLOAD {
	my $this=shift;
	my $property = $AUTOLOAD;
	$property =~ s|.*:||; # strip fully-qualified portion
	
	$this->{$property}=shift if @_;
	$this->{$property};
}

1
