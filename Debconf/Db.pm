#!/usr/bin/perl -w

=head1 NAME

Debconf::Db - debconf database setup

=cut

package Debconf::Db;
use strict;
use Debconf::Log qw{:all};
use Debconf::DbDriver;
use fields qw{config templates};

our Debconf::Db $opts=fields::new('Debconf::Db');
our $config;
our $templates;

=head1 DESCRIPTION

This module reads a config file and uses it to set up a set of debconf
database drivers. It doesn't actually implement the database; the drivers
do that.

The config file format is a series of stanzas. The first stanza configures
the debconf as a whole, and then each of the rest sets up a database driver.

This lacks the glorious nested bindish beauty of Wichert's original idea,
but it captures the essence of it.

This class makes available a $Debconf::Db::config, which is the root db
driver for storing state, and a $Debconf::Db::templates, which is the root
db driver for storing template data.

Requests can be sent directly to the db's by things like 
$Debconf::Db::config->setfield(...)

=head1 METHODS

=cut

# Turns a chunk of text into a hash. Returns number of lines of data
# that were processed.
sub _hashify($$) {
	my $text=shift;
	my $hashref=shift;

	my %ret;
	my $i;
	foreach my $line (split /\n/, $text) {
		next if $line=~/^\s*#/; # comment
		$i++;
		my ($key, $value)=split(/\s*:\s*/, $line, 2);
		$key=~tr/-/_/;
		die "Parse error" unless defined $key and length $key;
		$hashref->{lc($key)}=$value;
	}
	return $i;
}

=item load

Read a debconf config file, parse it, and set up the drivers.
Reads from the standard locations unless a filename to read is specified.

=cut

sub load {
	my $class=shift;
	my $cf=shift;
	if (! $cf) {
		$cf="$ENV{HOME}/.debconfrc"	if -e "$ENV{HOME}/.debconfrc";
		$cf="/etc/debconf.conf"		if -e "/etc/debconf.conf";
	}
	die "No config file found" unless $cf;

	debug db => "loading config file $cf";

	open (DEBCONF_CONFIG, $cf) or die "$cf: $!\n";
	local $/="\n\n"; # read a stanza at a time

	# Read global options stanza.
	1 until _hashify(<DEBCONF_CONFIG>, $opts);

	# Now read in each database driver, and set them up.
	# This assumes that there are no forward references in
	# the config file..
	while (<DEBCONF_CONFIG>) {
		my %driver=();
		next unless _hashify($_, \%driver);
		my $type=$driver{driver} or die "driver type not specified";
		# Make sure that the class is loaded..
		if (! UNIVERSAL::can("Debconf::DbDriver::$type", 'new')) {
			eval qq{use Debconf::DbDriver::$type};
			die $@ if $@;
		}
		delete $driver{driver}; # not a field for the object
		# Make object, and pass in the fields, and we're done with it.
		debug db => "making DbDriver of type $type";
		"Debconf::DbDriver::$type"->new(%driver);
	}
	close DEBCONF_CONFIG;

	# Look up the two database drivers.
	$config=Debconf::DbDriver->driver($opts->{config});
	if (not ref $config) {
		die "Configuration database \"".$opts->{config}."\" was not initialized.\n";
	}
	$templates=Debconf::DbDriver->driver($opts->{templates});
	if (not ref $templates) {
		die "Template database \"".$opts->{templates}."\" was not initialized.\n";
	}
}

=item save

Save the databases, and shutdown the drivers.

=cut

sub save {
	$config->savedb if $config;
	$templates->savedb if $templates;
	$config='';
	$templates='';
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
