#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::AutoSelect - automatic FrontEnd selection library.

=cut

package Debian::DebConf::AutoSelect;
use strict;
use Debian::DebConf::Gettext;
use Debian::DebConf::ConfModule;
use Debian::DebConf::Config qw(frontend);
use Debian::DebConf::Log qw(:all);
use base qw(Exporter);
use vars qw(@EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw(make_frontend make_confmodule);
%EXPORT_TAGS = (all => [@EXPORT_OK]);

=head1 DESCRIPTION

This library makes it easy to create FrontEnd and ConfModule objects. It starts
with the desired type of object, and tries to make it. If that fails, it
progressivly falls back to other types.

=cut

my %fallback=(
	# preferred frontend		# fall back to (list ref)
	'Web'			=>	['Slang', 'Dialog', 'Text'],
	'Dialog'		=>	['Slang', 'Text'],
	'Gtk'			=>	['Slang', 'Dialog', 'Text'],
	'Text'			=>	['Slang', 'Dialog'],
	'Slang'			=>	['Dialog', 'Text'],
	'Editor'		=>	['Text'],
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
	my $starttype=($type || frontend());

	foreach $type ($starttype, @{$fallback{$starttype}}, 'Noninteractive') {
		debug user => "trying frontend $type";
		$frontend=eval qq{
			use Debian::DebConf::FrontEnd::$type;
			Debian::DebConf::FrontEnd::$type->new();
		};
		return $frontend if defined $frontend;

		warn sprintf(gettext("failed to initialize frontend: %s"), $type);
		$@=~s/\n//s;
		warn "($@)\n";
	}

	die sprintf(gettext("Unable to start a frontend: %s"), $@);
}

=item make_confmodule

Pass the script (if any) the ConfModule will start up, (and optional
arguments to pass to it) and this creates and returns a ConfModule.

=cut

sub make_confmodule {
	my $confmodule=Debian::DebConf::ConfModule->new(frontend => $frontend);

	$confmodule->startup(@_) if @_;
	
	return $confmodule;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
