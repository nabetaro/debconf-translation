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

Templates support internationalization. If LANG or a related environment
variable is set, and you request a field from a template, it will see if
"$ENV{LANG}-field" exists, and if so return that instead.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Template;
use strict;
use Debian::DebConf::Base;
use vars qw(@ISA $AUTOLOAD);
@ISA=qw{Debian::DebConf::Base};

# Helper for parse, sets a field to a value.
sub _savefield {
	my $this=shift;
	my $field=shift;
	my $value=shift;
	my $extended=shift;

	if ($field ne '') {
		$this->$field($value);
		my $e="extended_$field";
		$this->$e($extended);
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
	die "Template does not contain a Template: line"
		unless $this->{template};
}

=head2 any_other_method

Set/get a property. This supports internationalization.

=cut

sub AUTOLOAD {
	my $this=shift;
	my $property = $AUTOLOAD;
	$property =~ s|.*:||; # strip fully-qualified portion
			
	$this->{$property}=shift if @_;

	# Check to see if i18n should be used.
	if ($ENV{LANGUAGE} || $ENV{LC_ALL} || $ENV{LANG} && 
	    exists $this->{$property.'-'.($ENV{LANGUAGE} || $ENV{LC_ALL} || $ENV{LANG})}) {
		$property.='-'.($ENV{LANGUAGE} || $ENV{LC_ALL} || $ENV{LANG});
	}

	return $this->{$property};
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
