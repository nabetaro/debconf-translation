#!/usr/bin/perl -w

=head1 NAME

Debconf::Question - Question object

=cut

package Debconf::Question;
use strict;
use Debconf::Db;
use Debconf::Log qw(:all);

=head1 DESCRIPTION

This is a an object that represents a Question. Each Question has some
associated data (which is stored in a backend database). To get at this data,
just use $question->fieldname to read a field, and $question->fieldname(value)
to write a field. Any field names at all can be used, the convention is to
lower-case their names. If a field that is not defined is read, and a field by
the same name exists on the Template the Question is mapped to, the value of
that field will be returned instead.

=head1 FIELDS

=over 4

=item name

Holds the name of the Question.

=back

=cut

use fields qw(name);

# Class data
our %question;

=head1 CLASS METHODS

=over 4

=item new(name, owner)

The name of the question to create, and an owner for the question must
be passed to this function.

New questions default to having their seen flag set to "false".

=cut

sub new {
	my Debconf::Question $this=shift;
	my $name=shift;
	my $owner=shift;
	die "A question called \"$name\" already exists"
		if exists $question{$name};
	unless (ref $this) {
		$this = fields::new($this);
	}
	$this->{name}=$name;
	# This is what actually creates the question in the db.
	return unless defined $this->addowner($owner);
	$this->flag('seen', 'false');
	return $question{$name}=$this;
}

=item get(name)

Get an existing question.

=cut

sub get {
	my Debconf::Question $this=shift;
	my $name=shift;
	return $question{$name} if exists $question{$name};
	if ($Debconf::Db::config->exists($name)) {
		$this = fields::new($this);
		$this->{name}=$name;
		return $question{$name}=$this;
	}
	return undef;
}

=item iterate

Iterate over all existing questions. If called without parameters, returns
an iterator object. If called with the iterator, returns the next question,
or undef if all have been iterated over.

=cut

sub iterate {
	my $this=shift;
	
	if (! @_) {
		return $Debconf::Db::config->iterate;
	}
	else {
		my $name=$Debconf::Db::config->iterate(@_);
		return unless defined $name;
		return $this->get($name);
	}
}

=back

=head1 METHODS

=over 4

=cut

# This is a helper function that expands variables in a string.
sub _expand_vars {
	my $this=shift;
	my $text=shift;
		
	return '' unless defined $text;

	my @vars=$Debconf::Db::config->variables($this->{name});
	
	my $rest=$text;
	my $result='';
	my $varval;
	while ($rest =~ m/^(.*?)\${([^{}]+)}(.*)$/sg) {
		$result.=$1;  # copy anything before the variable
		$rest=$3; # continue trying to expand rest of text
		$varval=$Debconf::Db::config->getvariable($this->{name}, $2);
		$result.=$varval if defined($varval); # expand the variable
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

=item variable

Set/get a variable. Pass in the variable name, and an optional value to set
it to. The value of the variable is returned.

=cut

sub variable {
	my $this=shift;
	my $var=shift;
	
	if (@_) {
		return $Debconf::Db::config->setvariable($this->{name}, $var, shift);
	}
	else {
		return $Debconf::Db::config->getvariable($this->{name}, $var);
	}
}

=item flag

Set/get a flag. Pass in the flag name, and an optional value ("true" or
"false") to set it to. The value of the flag is returned.

=cut

sub flag {
	my $this=shift;
	my $flag=shift;

	# This deprecated flag is now automatically mapped to the inverse of
	# the "seen" flag.
	if ($flag eq 'isdefault') {
		debug developer => "The isdefault flag is deprecated, use the seen flag instead";
		if (@_) {
			my $value=(shift eq 'true') ? 'false' : 'true';
			$Debconf::Db::config->setflag($this->{name}, 'seen', $value);
		}
		return ($Debconf::Db::config->getflag($this->{name}, 'seen') eq 'true') ? 'false' : 'true';
	}

	if (@_) {
		return $Debconf::Db::config->setflag($this->{name}, $flag, shift);
	}
	else {
		return $Debconf::Db::config->getflag($this->{name}, $flag);
	}
}

=item value

Get the current value of this Question. Will return the default value 
from the template if no value is set. Pass in a value to set the value.

=cut

sub value {
	my $this = shift;
	
	if (@_ == 0) {
		my $ret=$Debconf::Db::config->getfield($this->{name}, 'value');
		return $ret if defined $ret;
		return $this->template->default if ref $this->template;
	} else {
		return $Debconf::Db::config->setfield($this->{name}, 'value', shift);
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

=item addowner

Add an owner to the list of owners of this Question. Pass the owner name.
Adding an owner that is already listed has no effect.

=cut

sub addowner {
	my $this=shift;

	return $Debconf::Db::config->addowner($this->{name}, shift);
}

=item removeowner

Remove an owner from the list of owners of this Question. Pass the owner name
to remove.

=cut

sub removeowner {
	my $this=shift;

	return $Debconf::Db::config->removeowner($this->{name}, shift);
}

=item AUTOLOAD

Handles all fields except name, by creating accessor methods for them the
first time they are accessed. Fields are first looked for in the db, and
failing that, the associated Template is queried for fields.

Lvalues are not supported.

=cut

sub AUTOLOAD {
	(my $field = our $AUTOLOAD) =~ s/.*://;

	no strict 'refs';
	*$AUTOLOAD = sub {
		my $this=shift;

		if (@_) {
			return $Debconf::Db::config->setfield($this->{name}, $field, shift);
		}
		my $ret=$Debconf::Db::config->getfield($this->{name}, $field);
		return $ret if defined $ret;
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
