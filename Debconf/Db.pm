#!/usr/bin/perl -w

=head1 NAME

Debconf::Db - debconf database setup

=cut

package Debconf::Db;
use strict;

=head1 DESCRIPTION

This module reads a config file and uses it to set up a set of debconf
database drivers. It doesn't actually implement the database; the drivers
do that.

The config file format is a series of stanzas, each of which sets up
a database driver. For example:

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
  Readonly: 1
  Username: foo
  Password: bar
  # I don't want any passwords that might be floating around in there.
  Reject-Type: password
  Force-Flag-Seen: false
  # If this db is not accessible for whatever reason, carry on anyway.
  Required: 0

  # This special driver provides a few items from dhcp.
  Database: dhcp
  Driver: DHCP
  Required: 0
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
# * I need to implement the accept and reject thingies; add the fields to
#   DbDriver class I guess, and add a new method to check whether it 
#   accepts a given item. (Or do I need to break out a new type of object to
#   handle this? That would be a LOT more flexiable, and I could just
#   use new stanzas in the config file for those objects. Hmmmm.)
# * There's also the Force-Flag-Seen thing, which is really a more generic
#   forcing of any given flag to any vale, and should expand to forcing any
#   field to a value too, I'd think.
# * I need to modify stacks a bit, to make this example work. When setting a
#   value, call the accept method on each writable driver in turn, and write
#   to the first that accepts it, rather than always writing to topmost.
# * Parser for config file; object instantiation will be straightforward.
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

sub readconfig {
	my $config=shift;
	if (! $config) {
		$config="$ENV{HOME}/.debconfrc"
			if -e "$ENV{HOME}/.debconfrc";
		$config="/etc/debconf.cnf"
			if -e "/etc/debconf.cnf";
	}
	die "No config file found" unless $config;

	open (DEBCONF_CONFIG, $config) or die "$config: $!\n";
	while (<DEBCONF_CONFIG>) {
	}
	close DEBCONF_CONFIG;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
