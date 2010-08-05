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
use Debconf::Log q{:all};
use Debconf::Encoding;
use Debconf::Config;

# Class data
our %template;
$Debconf::Template::i18n=1;

# A hash of known template fields. Others are warned about.
our %known_field = map { $_ => 1 }
	qw{template description choices default type};

# Convince perl to not do encoding conversions on text output to stdout.
# Debconf does its own conversions.
binmode(STDOUT);
binmode(STDERR);
	
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

=item new(template, owner, type)

The name of the template to create must be passed to this function.

When a new template is created, a question is created with the same name
as the template. This is to ensure that the template has at least
one owner -- the question, and to make life easier for debconf users -- so
they don't have to manually register that question.

The owner field, then, is actually used to set the owner of the question.

=cut

sub new {
	my Debconf::Template $this=shift;
	my $template=shift || die "no template name specified";
	my $owner=shift || 'unknown';
	my $type=shift || die "no template type specified";
	
	# See if we can use an existing template.
	if ($Debconf::Db::templates->exists($template) and
	    $Debconf::Db::templates->owners($template)) {
		# If a question matching this template already exists in
		# the db, add the owner to it. This handles shared owner
		# questions.
		my $q=Debconf::Question->get($template);
		$q->addowner($owner, $type) if $q;

		# See if the template claims to own any questions that
		# cannot be found. If so, the db is corrupted; attempt to
		# recover.
		my @owners=$Debconf::Db::templates->owners($template);
		foreach my $question (@owners) {
			my $q=Debconf::Question->get($question);
			if (! $q) {
				warn sprintf(gettext("warning: possible database corruption. Will attempt to repair by adding back missing question %s."), $question);
				my $newq=Debconf::Question->new($question, $owner, $type);
				$newq->template($template);
			}
		}
		
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
		$q->addowner($owner, $type) if $q;
	}
	else {
		my $q=Debconf::Question->new($template, $owner, $type);
		$q->template($template);
	}
	
	# This is what actually creates the template in the db.
	return unless $Debconf::Db::templates->addowner($template, $template, $type);

	$Debconf::Db::templates->setfield($template, 'type', $type);
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

This class method controls whether internationalization is enabled for all
templates. Sometimes it may be necessary to get at the C values of fields,
bypassing internationalization. To enable this, set i18n to a false value.
This is only for when you explicitly want an untranslated version (which may
not be suitable for display), not merely for when a C locale is in use.

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
					die sprintf(gettext("Template #%s in %s has a duplicate field \"%s\" with new value \"%s\". Probably two templates are not properly separated by a lone newline.\n"), $., $file, $field, $value);
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
			if ($line=~/^([-_@.A-Za-z0-9]*):\s?(.*)/) {
				# Beginning of new field. First, save the
				# old one.
				$save->($field, $value, $extended, $file);
				$field=lc $1;
				$value=$2;
				$value=~s/\s*$//;
				$extended='';
				my $basefield=$field;
				$basefield=~s/-.+$//;
				if (! $known_field{$basefield}) {
					warn sprintf(gettext("Unknown template field '%s', in stanza #%s of %s\n"), $field, $., $file);
				}
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
				$bit=~s/\s*$//;
				$extended.="\n" if length $extended &&
				                   $extended !~ /[\n ]$/;
				$extended.=$bit."\n";
			}
			elsif ($line=~/^\s(.*)/) {
				# Continuation of field.
				my $bit=$1;
				$bit=~s/\s*$//;
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
		my $template=$this->new($data{template}, @_, $data{type});
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
			if ($key =~ m/-[a-z]{2}_[a-z]{2}(@[^_@.])?(-fuzzy)?$/) {
				my $casekey=$key;
				$casekey=~s/([a-z]{2})(@[^_@.]|)(-fuzzy|)$/uc($1).$2.$3/eg;
				$data.=ucfirst($casekey).": ".$_->$key."\n";
			}
			else {
				$data.=ucfirst($key).": ".$_->$key."\n";
			}
			my $e="extended_$key";
			my $ext=$_->$e;
			if (defined $ext) {
				# Add extended field.
				$Text::Wrap::break = qr/\n|\s(?=\S)/;
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

# Helpers for _getlocalelist
sub _addterritory {
	my $locale=shift;
	my $territory=shift;
	$locale=~s/^([^_@.]+)/$1$territory/;
	return $locale;
}
sub _addcharset {
	my $locale=shift;
	my $charset=shift;
	$locale=~s/^([^@.]+)/$1$charset/;
	return $locale;
}
# Returns the list of locale names as searched (with slight changes) by GNU libc
sub _getlocalelist {
	my $locale=shift;
	$locale=~s/(@[^.]+)//;
	my $modifier=$1;
	my ($lang, $territory, $charset)=($locale=~m/^
	     ([^_@.]+)      #  Language
	     (_[^_@.]+)?    #  Territory
	     (\..+)?        #  Charset
	     /x);
	my (@ret) = ($lang);
	@ret = map { $_.$modifier, $_} @ret if defined $modifier;
	@ret = map { _addterritory($_,$territory), $_} @ret if defined $territory;
	@ret = map { _addcharset($_,$charset), $_} @ret if defined $charset;
	return @ret;
}

# Helper for AUTOLOAD; calculate the current locale, with aliases expanded,
# and normalized. May also generate a fallback. Returns both.
sub _getlangs {
	my $language=setlocale(LC_MESSAGES);
	my @langs = ();
	# LANGUAGE has a higher precedence than LC_MESSAGES
	if (exists $ENV{LANGUAGE} && $ENV{LANGUAGE} ne '') {
		foreach (split(/:/, $ENV{LANGUAGE})) {
			push (@langs, _getlocalelist($_));
		}
	}
	return @langs, _getlocalelist($language);
}

# Lower-case language name because fields are stored in lower case.
my @langs=map { lc $_ } _getlangs();

sub AUTOLOAD {
	(my $field = our $AUTOLOAD) =~ s/.*://;
	no strict 'refs';
	*$AUTOLOAD = sub {
		my $this=shift;
		if (@_) {
			return $Debconf::Db::templates->setfield($this->{template}, $field, shift);
		}
		
		my $ret;
		my $want_i18n = $Debconf::Template::i18n && Debconf::Config->c_values ne 'true';

		# Check to see if i18n and/or charset encoding should
		# be used.
		if ($want_i18n && @langs) {
			foreach my $lang (@langs) {
				# Avoid displaying Choices-C values
				$lang = 'en' if $lang eq 'c';

				# First check for a field that matches the
				# language and the encoding. No charset
				# conversion is needed. This also takes care
				# of the old case where encoding is
				# not specified.
				$ret=$Debconf::Db::templates->getfield($this->{template}, $field.'-'.$lang);
				return $ret if defined $ret;
				
				# Failing that, look for a field that matches
				# the language, and do charset conversion.
				if ($Debconf::Encoding::charmap) {
					foreach my $f ($Debconf::Db::templates->fields($this->{template})) {
						if ($f =~ /^\Q$field-$lang\E\.(.+)/) {
							my $encoding = $1;
							$ret = Debconf::Encoding::convert($encoding, $Debconf::Db::templates->getfield($this->{template}, lc($f)));
							return $ret if defined $ret;
						}
					}
				}

				# For en, force the default template if no
				# language-specific template was found,
				# since English text is usually found in a
				# plain field rather than something like
				# Choices-en.UTF-8. This allows you to
				# override other locale variables for a
				# different language with LANGUAGE=en.
				last if $lang eq 'en';
			}
		} elsif (not $want_i18n && $field !~ /-c$/i) {
			# If i18n is turned off, try *-C first.
			$ret=$Debconf::Db::templates->getfield($this->{template}, $field.'-c');
			return $ret if defined $ret;
		}

		$ret=$Debconf::Db::templates->getfield($this->{template}, $field);
		return $ret if defined $ret;

		# If the user asked for a language-specific field, fall
		# back to the unadorned field. This allows *-C to be
		# used to force untranslated data, and *-* to fall back
		# to untranslated data if no translation is available.
		if ($field =~ /-/) {
			(my $plainfield = $field) =~ s/-.*//;
			$ret=$Debconf::Db::templates->getfield($this->{template}, $plainfield);
			return $ret if defined $ret;
			return '';
		}

		return '';
	};
	goto &$AUTOLOAD;
}

# Do nothing.
sub DESTROY {}

# Overload stringification so metaget of a question's template field
# returns the template name.
use overload
	'""' => sub {
		my $template=shift;
		$template->template;
	};

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
