#!/usr/bin/perl -w

=head1 NAME

Debconf::Template - Template object

=cut

package Debconf::Template;
use strict;
use POSIX;
use FileHandle;
use Debconf::Gettext;
use Text::Wrap;
use Text::Tabs;
use base qw(Debconf::Base);

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
"fieldname-$LANG" exists, and if so return that instead.

=cut

=head1 METHODS

=cut

=head2 fields

Returns a list of all fields that are present in the object.

=cut

sub fields {
	my $this=shift;

	return keys %$this;
}

=head2 merge

Pass in another Template and all the fields in that other template
will be copied over onto the Template the method is called on.

=cut

sub merge {
	my $this=shift;
	my $other=shift;

	# Breaking the abstraction just a little..
	foreach my $key (keys %$other) {
		$this->$key($other->{$key});
	}
}

=head2 clear

Clears all fields of the template.

=cut

sub clear {
	my $this=shift;

	# Breaking the abstraction just a little..
	foreach my $key (keys %$this) {
		delete $this->{$key};
	}
}

=head2 stringify

This may be called as either a class method (in which case it takes a list
of templates), or as a normal method (which makes it act on only the one
object). It converts the template objects back into template file format,
and returns a string containing the data.

=cut

sub stringify {
	my $proto=shift;

	my @templatestrings;
	foreach (ref $proto ? $proto : @_) {
		my $data='';
		# Order the fields with Template and Type the top and the
		# rest sorted.
		foreach my $key ('template', 'type',
		                 (grep { $_ ne 'template' && $_ ne 'type'} sort keys %$_)) {
			next if $key=~/^extended_/;
			$data.=ucfirst($key).": ".$_->{$key}."\n";
			if (exists $_->{"extended_$key"}) {
				# Add extended field.
				my $extended=expand(wrap(' ', ' ', $_->{"extended_$key"}));
				# The word wrapper sometimes outputs
				# multiple " \n" lines, so collapse those
				# into one.
				$extended=~s/(\n )+\n/\n .\n/g;
				$data.=$extended."\n" if length $extended;
			}
		}
		push @templatestrings, $data;
	}
	return join("\n", @templatestrings);
}

=head2 load

This class method reads a templates file, instantiates a template for each
item in it, and returns all the instantiated templates. Pass it the file to
load (or an already open FileHandle).

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
		my $template=$this->new;
		$template->parse($_, $file);
		push @ret, $template;
	}

	return @ret;
}

=head2 parse

This method parses a string containing a template and stores all the
information in the Template object. It returns the object.

An optional second parameter can hold the name of the file that the
template came from, which is used in error messages.

=cut

sub parse {
	my $this=shift;
	my $text=shift;
	my $file=shift || gettext("unknown file");
	
	# Ignore any number of leading and trailing newlines.
	$text=~s/^\n+//;
	$text=~s/\n+$//;
	
	my ($field, $value, $extended)=('', '', '');
	foreach (split "\n", $text) {
		chomp;
		if (/^([-_.A-Za-z0-9]*):\s+(.*)/) {
			# Beginning of new field. First, save the old one.
			$this->_savefield($field, $value, $extended);
			$field=lc $1;
			$value=$2;
			$value=~s/\s*$//;
			$extended='';
		}
		elsif (/^\s\.$/) {
			# Continuation of field that contains only a blank line.
			$extended.="\n\n";
		}
		elsif (/^\s(\s+.*)/) {
			# Continuation of a field, with a doubly indented
			# bit that should not be wrapped.
			my $line=$1;
			$extended.="\n" unless $extended=~/\n$/;
			$extended.=$line."\n";
		}
		elsif (/^\s(.*)/) {
			# Continuation of field.
			$extended.=$1." ";
		}
		else {
			die sprintf(gettext("Template parse error near `%s', in stanza #%s of %s\n"), $_, $., $file);
		}
	}

	$this->_savefield($field, $value, $extended);

	# Sanity checks.
	die sprintf(gettext("Template #%s in %s does not contain a `Template:' line\n"), $., $file)
		unless $this->template;
	
	return $this;
}

# Helper for parse, sets a field to a value.
sub _savefield {
	my $this=shift;
	my $field=shift;
	my $value=shift;
	my $extended=shift;

	# Make sure there are no blank lines at the end of the extended 
	# field, as that causes problems when stringifying and elsewhere,
	# and is pointless anyway.
	$extended=~s/\n+$//;

	if ($field ne '') {
		$this->$field($value);
		my $e="extended_$field"; # silly perl..
		$this->$e($extended) if length $extended;
	}
}

# Calculate the current locale, with aliases expanded, and normalized.
# May also generate a fallback. Returns both.
sub _getlangs {
	# I really dislike hard-coding 5 here, but the POSIX module sadly does
	# not let us get at the value of LC_MESSAGES in locale.h in a more 
	# portable way.
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

=head2 i18n

This class method controls whether internationalzation is enabled for all 
templates. Sometimes it may be necessary to get at the C values of fields,
bypassing internationalization. To enable this, set i18n to a false value.

=cut

my $i18n=1;

sub i18n {
	my $class=shift;
	$i18n=shift;
}

=head2 AUTOLOAD

Creates and calls accessor methods to handle fields. 
This supports internationalization, but not lvalues.

=cut

{
	my @langs=_getlangs();

	sub AUTOLOAD {
		(my $field = our $AUTOLOAD) =~ s/.*://;

		no strict 'refs';
		*$AUTOLOAD = sub {
			my $this=shift;
		
			$this->{$field}=shift if @_;
		
			# Check to see if i18n should be used.
			if ($i18n && @langs) {
				foreach my $lang (@langs) {
					return $this->{$field.'-'.$lang}
						if exists $this->{$field.'-'.$lang};
				}
			}
		
			return $this->{$field};
		};
		goto &$AUTOLOAD;
	}
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
