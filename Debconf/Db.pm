#!/usr/bin/perl -w

=head1 NAME

Debconf::Db - debconf databases

=cut

package Debconf::Db;
use strict;
use Debconf::Log qw{:all};
use Debconf::Config;
use Debconf::DbDriver;
our $config;
our $templates;

=head1 DESCRIPTION

This class makes available a $Debconf::Db::config, which is the root db
driver for storing state, and a $Debconf::Db::templates, which is the root
db driver for storing template data.

Requests can be sent directly to the db's by things like 
$Debconf::Db::config->setfield(...)

=head1 CLASS METHODS

=item load

Loads up the database drivers.

If a hash of parameters are passed, those parameters are used as the defaults
for *every* database driver that is loaded up. Practically, setting 
(readonly => "true") is the only use of this.

=cut

sub load {
	my $class=shift;

	Debconf::Config->load('', @_); # load default config file
	$config=Debconf::DbDriver->driver(Debconf::Config->config);
	if (not ref $config) {
		die "Configuration database \"".Debconf::Config->config.
			"\" was not initialized.\n";
	}
	$templates=Debconf::DbDriver->driver(Debconf::Config->templates);
	if (not ref $templates) {
		die "Template database \"".Debconf::Config->templates.
			"\" was not initialized.\n";
	}
}

=item makedriver

Set up a driver. Pass it all the fields the driver needs, and one more
field, called "driver" that specifies the type of driver to make.

=cut

sub makedriver {
	my $class=shift;
	my %config=@_;

	my $type=$config{driver} or die "driver type not specified (perhaps you need to re-read debconf.conf(5))";

	# Make sure that the class is loaded..
	if (! UNIVERSAL::can("Debconf::DbDriver::$type", 'new')) {
		eval qq{use Debconf::DbDriver::$type};
		die $@ if $@;
	}
	delete $config{driver}; # not a field for the object
	
	# Make object, and pass in the config, and we're done with it.
	debug db => "making DbDriver of type $type";
	"Debconf::DbDriver::$type"->new(%config);
}

=item save

Save the databases, and shutdown the drivers.

=cut

sub save {
	# FIXME: Debconf::Db->save shutdown only
	# drivers which are declared in Config and Templates fields
	# in conf file while load method (see above) make and init ALL drivers

	$config->shutdown if $config;
	# FIXME: if debconf is killed right here, the db is inconsistent.
	$templates->shutdown if $templates;
	$config='';
	$templates='';
}

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
