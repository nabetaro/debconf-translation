#!/usr/bin/perl -w

=head1 NAME

Debconf::Db - debconf database setup

=cut

package Debconf::Db;
use strict;
use fields qw{root};
use Debconf::DbDriver;
our Debconf::Db $config=fields::new('Debconf::Db');
our $rootdriver;

=head1 DESCRIPTION

This module reads a config file and uses it to set up a set of debconf
database drivers. It doesn't actually implement the database; the drivers
do that.

The config file format is a series of stanzas. The first stanza configures
the database as a whole, and then each of the rest sets up a database driver.
For example:

  # This stanza is used for general debconf setup.
  Root: main

  # This is my own local database.
  Database: mydb
  Driver: Text
  Directory: /var/lib/debconf

  # This is another database that I use to hold only X server configuration.
  Database: X
  Driver: Text
  Directory: /etc/X11/debconf/
  # It's sorta hard to work out what questions belong to X; it
  # should be using a deeper tree structure so I could just match on ^X/
  # Oh well.
  Accept-Name: xserver|xfree86|xbase
  
  # This is our company's global, read-only (for me!) debconf database.
  Database: company
  Driver: SQL
  Server: debconf.foo.com
  Readonly: true
  Username: foo
  Password: bar
  # I don't want any passwords that might be floating around in there.
  Reject-Type: password
  Force-Flag-Seen: false
  # If this db is not accessible for whatever reason, carry on anyway.
  Required: false

  # This special driver provides a few items from dhcp.
  Database: dhcp
  Driver: DHCP
  Required: false
  Reject-Type: password

  # And I use this database to hold passwords safe and secure.
  Database: passwords
  Driver: FlatFile
  File: /etc/debconf/passwords
  Mode: 600
  Owner: root
  Group: root
  Accept-Type: password

  # Let's put them all together in a database stack.
  Database: main
  Driver: Stack
  Stack: passwords, X, mydb, company, dhcp
  # So, all passwords go to the password database. Most X configuration
  # stuff goes to the x database, and anything else goes to my main
  # database. Values are looked up in each of those in turn, and if none has 
  # a particular value, it is looked up in the company-wide database 
  # or maybe dhcp (unless it's a password).

This lacks the glorious nested bindish beauty of Wichert's original idea,
but it captures the essence of it.

=cut

# TODO:
# * There's also the Force-Flag-Seen thing, which is really a more generic
#   forcing of any given flag to any vale, and should expand to forcing any
#   field to a value too, I'd think.
# * Hook into the Question class.
# * DbDriver's need access to Templates so they can tell what Type a
#   given item is.
# * Make FlatDir write out password type thing mode 600.
# * Do something about Templates. What, I dunno.
# * Transition from perldb.

=head1 METHODS

=head2 readconfig([file])

Read the specified config file. If none is specified, try
$ENV{HOME}/.debconfrc, and /etc/debconf.cnf.

=cut

sub _hashify($$) {
	my $text=shift;
	my $hashref=shift;

	my %ret;
	foreach my $line (split /\n/, $text) {
		next if $line=~/^\s*#/; # comment
		my ($key, $value)=split(/\s*:\s*/, $line, 2);
		$key=~tr/-/_/;
		die "Parse error" unless defined $key and length $key;
		$hashref->{lc($key)}=$value;
	}
}

sub readconfig {
	my $class=shift;
	my $cf=shift;
	if (! $cf) {
		$cf="$ENV{HOME}/.debconfrc"	if -e "$ENV{HOME}/.debconfrc";
		$cf="/etc/debconf.cnf"		if -e "/etc/debconf.cnf";
	}
	die "No config file found" unless $cf;

	open (DEBCONF_CONFIG, $cf) or die "$cf: $!\n";
	local $/="\n\n"; # read a stanza at a time

	# Read global config stanza.
	_hashify(<DEBCONF_CONFIG>, $config);
	die "Root database not specified" unless exists $config->{root};
	
	# Now read in each database driver, and set them up.
	# This assumes that there are no forward references in
	# the config file..
	while (<DEBCONF_CONFIG>) {
		my %driver;
		_hashify($_, \%driver);
		my $type=$driver{driver} or die "driver type not specified";
		# Make sure that the class is loaded..
		if (! UNIVERSAL::can("Debconf::DbDriver::$type", 'new')) {
			eval qq{use Debconf::DbDriver::$type};
			die $@ if $@;
		}
		delete $driver{driver}; # not a field for the object
		# Make object, and pass in the fields, and we're done with it.
		"Debconf::DbDriver::$type"->new(%driver);
	}
	close DEBCONF_CONFIG;

	# Look up the root driver.
	$rootdriver=Debconf::DbDriver->driver($config->{root});
	if (not ref $rootdriver) {
		die "Root database driver \"".$config->{root}."\" was not initialized.\n";
	}
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
