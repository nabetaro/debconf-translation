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
  Driver: text
  Directory: /var/lib/debconf

  # This is another database that I use to hold only X server configuration.
  Database: X
  Driver: text
  Directory: /etc/X11/debconf/
  # It's sorta hard to work out what questions belong to X; it
  # should be using a deeper tree structure so I could just match on ^X/
  # Oh well.
  Accept-Name: xserver|xfree86|xbase
  
  # This is our company's global, read-only (for me!) debconf database.
  Database: company
  Driver: sql
  Server: debconf.foo.com
  Readonly: 1
  Username: foo
  Password: bar
  # I don't want any passwords that might be floating around in there.
  Rehect-Type: password

  # And I use this database to hold passwords safe and secure.
  Database: passwords
  Driver: flatfile
  File: /etc/passwords.debconf.db
  FileMode: 600
  Accept-Type: password

  # So let's put them all together. I'll make a database stack.
  Database: main
  Driver: stack
  Stack: passwords, X, mydb, company
  # So, all passwords go to the password database. Most X configuration
  # stuff goes to the x database, and anything else goes to my main
  # database. Values are looked up in each of those in turn, and if none has 
  # a particular value, it is looked up in the company-wide database (unless
  # it's a password).

This lacks the glorious nested bindish beauty of Wichert's original idea,
but it captures the essence of it.

=cut

# TODO:
# * I need to implement the accept and reject thingies; add the fields to
#   DbDriver class I guess, and add a new method to check whether it 
#   accepts a given item. (Or do I need to break out a new type of object to
#   handle this? That would be a LOT more flexiable, and I could just
#   use new stanzas in the config file for those objects. Hmmmm.)
# * I need to modify stacks a bit, to make this example work. When setting a
#   value, call the accept method on each writable driver in turn, and write
#   to the first that accepts it, rather than always writing to topmost.
# * Parser for config file; object instantiation will be straightforward.
# * Hook this into the Question class.
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
