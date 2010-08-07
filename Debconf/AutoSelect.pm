#!/usr/bin/perl -w

=head1 NAME

Debconf::AutoSelect - automatic FrontEnd selection library.

=cut

package Debconf::AutoSelect;
use strict;
use Debconf::Gettext;
use Debconf::ConfModule;
use Debconf::Config;
use Debconf::Log qw(:all);
use base qw(Exporter);
our @EXPORT_OK = qw(make_frontend make_confmodule);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

=head1 DESCRIPTION

This library makes it easy to create FrontEnd and ConfModule objects. It
starts with the desired type of object, and tries to make it. If that fails,
it progressively falls back to other types in the list.

=cut

my %fallback=(
	# preferred frontend		# fall back to
	'Kde'			=>	['Dialog', 'Readline', 'Teletype'],
	'Gnome'			=>	['Dialog', 'Readline', 'Teletype'],
	'Web'			=>	['Dialog', 'Readline', 'Teletype'],
	'Dialog'		=>	['Readline', 'Teletype'],
	'Gtk'			=>	['Dialog', 'Readline', 'Teletype'],
	'Readline'		=>	['Teletype', 'Dialog'],
	'Editor'		=>	['Readline', 'Teletype'],
	# Here to make upgrades clean for those who used to use the slang
	# frontend.
	'Slang'			=>	['Dialog', 'Readline', 'Teletype'],
	# And the Text frontend has become the Readline frontend.
	'Text'			=> 	['Readline', 'Teletype', 'Dialog'],

);

my $frontend;
my $type;

=head1 METHODS

=over 4

=item make_frontend

Creates and returns a FrontEnd object. The type of FrontEnd used varies. It
will try the preferred type first, and if that fails, fall back through
other types, all the way to a Noninteractive frontend if all else fails.

=cut

sub make_frontend {
	my $script=shift;
	my $starttype=ucfirst($type) if defined $type;
	if (! defined $starttype || ! length $starttype) {
		$starttype = Debconf::Config->frontend;
		if ($starttype =~ /^[A-Z]/) {
			warn "Please do not capitalize the first letter of the debconf frontend.";
		}
		$starttype=ucfirst($starttype);
	}

	my $showfallback=0;
	foreach $type ($starttype, @{$fallback{$starttype}}, 'Noninteractive') {
		if (! $showfallback) {
			debug user => "trying frontend $type";
		}
		else {
			warn(sprintf(gettext("falling back to frontend: %s"), $type));
		}
		$frontend=eval qq{
			use Debconf::FrontEnd::$type;
			Debconf::FrontEnd::$type->new();
		};
		return $frontend if defined $frontend;

		warn sprintf(gettext("unable to initialize frontend: %s"), $type);
		$@=~s/\n.*//s;
		warn "($@)";
		$showfallback=1;
	}

	die sprintf(gettext("Unable to start a frontend: %s"), $@);
}

=item make_confmodule

Pass the script (if any) the ConfModule will start up, (and optional
arguments to pass to it) and this creates and returns a ConfModule.

=cut

sub make_confmodule {
	my $confmodule=Debconf::ConfModule->new(frontend => $frontend);

	$confmodule->startup(@_) if @_;
	
	return $confmodule;
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
