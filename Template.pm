#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Template - Template object

=cut

=head1 DESCRIPTION

This is an object that represents a Template. Each Template has some associated
data, the fields of the template structure. To get at this data, just use 
$template->fieldname to read a field, and $template->fieldname(value) to write a
field. Any field names at all can be used, the convention is to lower-case their
names. All Templates should have a "template" field that is their name. Most have
"default", "type", and "description" fields as well. The field named 
"extended_description" holds the extended description, if any.

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
		$value=~s/\s+/ /;
		$this->$field([split(/, ?/, $value)]);
	}
	elsif ($field ne '') {
		$this->$field($value);
	}
}

=head2 merge

Pass this another Template and all properties of the object you
call this method on will be copied over onto the other Template
and any old values in the other Template will be removed.

=cut

sub merge {
	my $this=shift;
	my $other=shift;

	# Breaking the abstraction just a little..
	foreach my $key (keys %$other) {
		delete $other->{$key};
	}

	foreach my $key (keys %$this) {
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
