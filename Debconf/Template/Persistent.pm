#!/usr/bin/perl -w

=head1 NAME

Debconf::Template::Persistent - Template object with persistence.

=cut

package Debconf::Template::Persistent;
use strict;
use Debconf::Db;
use base 'Debconf::Template';

# Class data
our %template;

=head1 DESCRIPTION

This is a varient of Debconf::Template that can be made persistent and
stored and retreived via a Debconf::DbDriver.

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
	return $template{$template} if exists $template{$template};
	if ($Debconf::Db::templates->exists($template)) {
		$this = fields::new($this);
		$this->{template}=$template;
		return $template{$template}=$this;
	}

	# Really making a new template.
	unless (ref $this) {
		$this = fields::new($this);
	}
	$this->{template}=$template;
	# Create a question in the db to go with it.
	unless ($Debconf::Db::config->exists($template)) {
		return unless $Debconf::Db::config->addowner($template, $owner);
		# The question has this template as its template.
		return unless $Debconf::Db::config->setfield($template, "template", $template);
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

=head2 save

Save all changes to templates in this class.

=cut

sub save {
	my $this=shift;

	$Debconf::Db::templates->savedb;
}

=head1 METHODS

=head2 AUTOLOAD

Creates and calls accessor methods to handle fields.
This supports internationalization, but not lvalues.
It pulls data out of the backend db.

=cut

{
	my @langs=Debconf::Template::_getlangs();

	sub AUTOLOAD {
		(my $field = our $AUTOLOAD) =~ s/.*://;
		no strict 'refs';
		*$AUTOLOAD = sub {
			my $this=shift;

			if (@_) {
				return $Debconf::Db::templates->setfield($this->{template}, $field, shift);
			}
		
			# Check to see if i18n should be used.
			if ($Debconf::Template::i18n && @langs) {
				foreach my $lang (@langs) {
					# Lower-case language name because
					# fields are stored in lower case.
					my $ret=$Debconf::Db::templates->getfield($this->{template}, $field.'-'.lc($lang));
					return $ret if defined $ret;
				}
			}
			return $Debconf::Db::templates->getfield($this->{template}, $field);
		};
		goto &$AUTOLOAD;
	}
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
