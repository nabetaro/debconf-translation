#!/usr/bin/perl -w

=head1 NAME

Debconf::Template - Template object with persistence.

=cut

package Debconf::Template;
use strict;
use POSIX;
use FileHandle;
use Debconf::Gettext;
use Text::Wrap;
use Text::Tabs;
use Debconf::Db;
use Debconf::Iterator;
use Debconf::Question;
use fields qw(template);

# Class data
our %template;
$Debconf::Template::i18n=1;

=head1 DESCRIPTION

This is an object that represents a Template. Each Template has some associated
data, the fields of the template structure. To get at this data, just use
$template->fieldname to read a field, and $template->fieldname(value) to write
a field. Any field names at all can be used, the convention is to lower-case
their names. 

Common fields are "default", "type", and "description". The field
named "extended_description" holds the extended description, if any.

Templates support internationalization. If LANG or a related environment
variable is set, and you request a field from a template, it will see if
"fieldname-$LANG" exists, and if so return that instead.

=cut

=head1 CLASS METHODS

=item new(template, owner)

The name of the template to create must be passed to this function.

When a new template is created, a question is created with the same name
as the template. This is to ensure that the template has at least
one owner -- the question, and to make life easier for debcofn users -- so
they don't have to manually register that question.

The owner field, then, is actually used to set the owner of the question.

=cut

sub new {
	my Debconf::Template $this=shift;
	my $template=shift || die "no template name specified";
	my $owner=shift || 'unknown';
	
	# See if we can use an existing template.
	if ($Debconf::Db::templates->exists($template) and
	    $Debconf::Db::templates->owners($template)) {
		# If a question matching this template already exists in
		# the db, add the owner to it. This handles shared owner
		# questions.
		my $q=Debconf::Question->get($template);
		$q->addowner($owner) if $q;
		
		$this = fields::new($this);
		$this->{template}=$template;
		return $template{$template}=$this;
	}

	# Really making a new template.
	unless (ref $this) {
		$this = fields::new($this);
	}
	$this->{template}=$template;
	# Create a question in the db to go with it, unless
	# one with the same name already exists. If one with the same name
	# exists, it may be a shared question so we add the current owner
	# to it.
	if ($Debconf::Db::config->exists($template)) {
		my $q=Debconf::Question->get($template);
		$q->addowner($owner) if $q;
	}
	else {
		my $q=Debconf::Question->new($template, $owner);
		$q->template($template);
	}
	
	# This is what actually creates the template in the db.
	return unless $Debconf::Db::templates->addowner($template, $template);

	return $template{$template}=$this;
}

=head2 get(templatename)

Get an existing template (it may be pulled out of the database, etc).

=cut

sub get {
	my Debconf::Template $this=shift;
	my $template=shift;
	return $template{$template} if exists $template{$template};
	if ($Debconf::Db::templates->exists($template)) {
		$this = fields::new($this);
		$this->{template}=$template;
		return $template{$template}=$this;
	}
	return undef;
}

=head2 i18n

This class method controls whether internationalzation is enabled for all 
templates. Sometimes it may be necessary to get at the C values of fields,
bypassing internationalization. To enable this, set i18n to a false value.

=cut

sub i18n {
	my $class=shift;
	$Debconf::Template::i18n=shift;
}

=head2 load

This class method reads a templates file, instantiates a template for each
item in it, and returns all the instantiated templates. Pass it the file to
load (or an already open FileHandle).

Any other parameters that are passed to this function will be passed on to
the template constructor when it is called.

=cut

sub load {
	my $this=shift;
	my $file=shift;

	my @ret;
	my $fh;

	if (ref $file) {
		$fh=$file;
	}
	else {
		$fh=FileHandle->new($file) || die "$file: $!";
	}
	local $/="\n\n"; # read a template at a time.
	while (<$fh>) {
		# Parse the data into a hash structure.
		my %data;
		
		# Sets a field to a value in the hash, with sanity
		# checking.
		my $save = sub {
			my $field=shift;
			my $value=shift;
			my $extended=shift;
			my $file=shift;

			# Make sure there are no blank lines at the end of
			# the extended field, as that causes problems when 
			# stringifying and elsewhere, and is pointless
			# anyway.
			$extended=~s/\n+$//;

			if ($field ne '') {
				if (exists $data{$field}) {
					die sprintf(gettext("Template #%s in %s has a duplicate field \"%s\" with new value \"%s\". Probably two templates are not properly seperated by a lone newline.\n"), $., $file, $field, $value);
				}
				$data{$field}=$value;
				$data{"extended_$field"}=$extended
					if length $extended;
			}
		};

		# Ignore any number of leading and trailing newlines.
		s/^\n+//;
		s/\n+$//;
		my ($field, $value, $extended)=('', '', '');
		foreach my $line (split "\n", $_) {
			chomp $line;
			if ($line=~/^([-_.A-Za-z0-9]*):\s?(.*)/) {
				# Beginning of new field. First, save the
				# old one.
				$save->($field, $value, $extended, $file);
				$field=lc $1;
				$value=$2;
				$value=~s/\s*$//;
				$extended='';
			}
			elsif ($line=~/^\s\.$/) {
				# Continuation of field that contains only 
				# a blank line.
				$extended.="\n\n";
			}
			elsif ($line=~/^\s(\s+.*)/) {
				# Continuation of a field, with a doubly
				# indented bit that should not be wrapped.
				my $bit=$1;
				$extended.="\n" if length $extended &&
				                   $extended !~ /[\n ]$/;
				$extended.=$bit."\n";
			}
			elsif ($line=~/^\s(.*)/) {
				# Continuation of field.
				my $bit=$1;
				$extended.=' ' if length $extended &&
				                  $extended !~ /[\n ]$/;
				$extended.=$bit;
			}
			else {
				die sprintf(gettext("Template parse error near `%s', in stanza #%s of %s\n"), $line, $., $file);
			}
		}
		$save->($field, $value, $extended, $file);

		# Sanity checks.
		die sprintf(gettext("Template #%s in %s does not contain a 'Template:' line\n"), $., $file)
			unless $data{template};

		# Create and populate template from hash.
		my $template=$this->new($data{template}, @_);
		# Ensure template is empty, then fill with new data.
		$template->clearall;
		foreach my $key (keys %data) {
			next if $key eq 'template';
			$template->$key($data{$key});
		}
		push @ret, $template;
	}

	return @ret;
}
					
=head1 METHODS

=head2 template

Returns the name of the template.

=cut

sub template {
	my $this=shift;

	return $this->{template};
}

=head2 fields

Returns a list of all fields that are present in the object.

=cut

sub fields {
	my $this=shift;

	return $Debconf::Db::templates->fields($this->{template});
}

=head2 clearall

Clears all the fields of the object.

=cut

sub clearall {
	my $this=shift;

	foreach my $field ($this->fields) {
		$Debconf::Db::templates->removefield($this->{template}, $field);
	}
}

=head2 merge

Pass in another Template and all the fields in that other template
will be copied over onto the Template the method is called on.

=cut

sub merge {
	my $this=shift;
	my $other=shift;

	foreach my $field ($other->fields) {
		$this->$field($other->$field);
	}
}

=head2 stringify

This may be called as either a class method (in which case it takes a list
of templates), or as a normal method (which makes it act on only the one
object). It converts the template objects back into template file format,
and returns a string containing the data.

=cut

sub stringify {
	my $this=shift;

	my @templatestrings;
	foreach (ref $this ? $this : @_) {
		my $data='';
		# Order the fields with Template and Type the top and the
		# rest sorted.
		foreach my $key ('template', 'type',
			(grep { $_ ne 'template' && $_ ne 'type'} sort $_->fields)) {
			next if $key=~/^extended_/;
			# Support special case of -ll_LL items.
			if ($key =~ m/-[a-z]{2}_[a-z]{2}$/) {
				my $casekey=$key;
				$casekey=~s/([a-z]{2})$/uc($1)/eg;
				$data.=ucfirst($casekey).": ".$_->$key."\n";
			}
			else {
				$data.=ucfirst($key).": ".$_->$key."\n";
			}
			my $e="extended_$key";
			my $ext=$_->$e;
			if (defined $ext) {
				# Add extended field.
				my $extended=expand(wrap(' ', ' ', $ext));
				# The word wrapper sometimes outputs multiple
				# " \n" lines, so collapse those into one.
				$extended=~s/(\n )+\n/\n .\n/g;
				$data.=$extended."\n" if length $extended;
			}
		}
		push @templatestrings, $data;
	}
	return join("\n", @templatestrings);
}

=head2 AUTOLOAD

Creates and calls accessor methods to handle fields.
This supports internationalization.
It pulls data out of the backend db.

=cut

# Helper for AUTOLOAD; calculate the current locale, with aliases expanded,
# and normalized. May also generate a fallback. Returns both.
sub _getlangs {
	# I really dislike hard-coding 5 here, but the POSIX module sadly
	# does not let us get at the value of LC_MESSAGES in locale.h in a
	# more portable way.
	# FIXME: perl does now allow it; use POSIX qw{LC_MESSAGES}.
	# I am waiting on changing that until the perl that supports it
	# hits testing, and I will need to (pre?)depend on it then.
	my $language=setlocale(5); # LC_MESSAGES
	if ($language eq 'C' || $language eq 'POSIX') {
		return;
	}
	# Try to do one level of fallback.
	elsif ($language=~m/^(\w\w)_/) {
		return $language, $1;
	}
	return $language;
}

{
	my @langs=_getlangs();

	sub AUTOLOAD {
		(my $field = our $AUTOLOAD) =~ s/.*://;
		no strict 'refs';
		*$AUTOLOAD = sub {
			my $this=shift;

			if (@_) {
				return $Debconf::Db::templates->setfield($this->{template}, $field, shift);
			}
		
			my $ret;
			# Check to see if i18n should be used.
			if ($Debconf::Template::i18n && @langs) {
				foreach my $lang (@langs) {
					# Lower-case language name because
					# fields are stored in lower case.
					$ret=$Debconf::Db::templates->getfield($this->{template}, $field.'-'.lc($lang));
					return $ret if defined $ret;
				}
			}
			$ret=$Debconf::Db::templates->getfield($this->{template}, $field);
			return $ret if defined $ret;
			return '';
		};
		goto &$AUTOLOAD;
	}
}

# Do nothing.
sub DESTROY {}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
