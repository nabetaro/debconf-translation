#!/usr/bin/perl -w

=head1 NAME

Debconf::Config - Debconf meta-configuration module

=cut

package Debconf::Config;
use strict;
use Debconf::Question;
use Debconf::Gettext;
use Debconf::Db;

use fields qw(config templates frontend priority helpvisible
              showold admin_email log debug);
our $config=fields::new('Debconf::Config');

our @config_files=("$ENV{HOME}/.debconfrc", "/etc/debconf.conf",
                   "/usr/share/debconf/debconf.conf");

=head1 DESCRIPTION

This package holds configuration values for debconf. It supplies defaults,
and allows them to be overridden by values from the environment, the config
file, and values pulled out of the debconf database.

=head1 METHODS

=over 4

=item load

Reads and parses a config file. The config file format is a series of stanzas;
the first stanza configures debconf as a whole, and then each of the rest sets
up a database driver. This lacks the glorious nested bindish beauty of 
Wichert's original idea, but it captures the essence of it. It will load
from a set of standard locations unless a file to load is specified.

=cut

# Turns a chunk of text into a hash. Returns number of fields
# that were processed. Also handles env variable expansion.
sub _hashify ($$) {
	my $text=shift;
	my $hash=shift;

	$text =~ s/\${([^}]+)}/$ENV{$1}/eg;
	
	my %ret;
	my $i;
	foreach my $line (split /\n/, $text) {
		next if $line=~/^\s*#/; # comment
		next if $line=~/^\s*$/; # blank
		$i++;
		my ($key, $value)=split(/\s*:\s*/, $line, 2);
		$key=~tr/-/_/;
		die "Parse error" unless defined $key and length $key;
		$hash->{lc($key)}=$value;
	}
	return $i;
}

sub load {
	my $class=shift;
	my $cf=shift;
	
	if (! $cf) {
		for my $file (@config_files) {
			$cf=$file, last if -e $file;
		}
	}
	die "No config file found" unless $cf;

	open (DEBCONF_CONFIG, $cf) or die "$cf: $!\n";
	local $/="\n\n"; # read a stanza at a time

	# Read global options stanza.
	1 until _hashify(<DEBCONF_CONFIG>, $config);

	# Verify that all options are sane.
	if (! exists $config->{config}) {
		print STDERR gettext("Config database not specified in config file.");
		exit(1);
	}
	if (! exists $config->{templates}) {
		print STDERR gettext("Template database not specified in config file.");
		exit(1);
	}

	# Now read in each database driver, and set it up.
	while (<DEBCONF_CONFIG>) {
		my %config=();
		next unless _hashify($_, \%config);
		Debconf::Db->makedriver(%config);
	}
	close DEBCONF_CONFIG;
}

=item frontend

The frontend to use. Looks at first the value of DEBIAN_FRONTEND, second the
config file, third the database, and if all of those fail, defaults to the
dialog frontend.

If a value is passed to this function, it changes it temporarily (for
the lifetime of the program) to override what's in the database or config
file.

=cut

sub frontend {
	my $class=shift;
	return $ENV{DEBIAN_FRONTEND} if exists $ENV{DEBIAN_FRONTEND};
	$config->{frontend}=shift if @_;
	return $config->{frontend} if exists $config->{frontend};
	
	my $ret='Dialog';
	my $question=Debconf::Question->get('debconf/frontend');
	if ($question) {
		$ret=$question->value || $ret;
	}
	return $ret;
}

=item priority

The lowest priority of questions you want to see. Looks at first the value
of DEBIAN_PRIORITYD, second the config file, third the database, and if all
of those fail, defaults to "medium".

If a value is passed to this function, it changes it temporarily (for
the lifetime of the program) to override what's in the database or config
file.

=cut

sub priority {
	my $class=shift;
	return $ENV{DEBIAN_PRIORITY} if exists $ENV{DEBIAN_PRIORITY};
	$config->{priority}=shift if @_;
	return $config->{priority} if exists $config->{priority};

	my $ret='medium';
	my $question=Debconf::Question->get('debconf/priority');
	if ($question) {
		$ret=$question->value || $ret;
	}
	return $ret;
}

=item helpvisible

Whether extended help should be displayed in some frontends. Looks first at
the config file, then at the database, and if both fail, defaults to true.

If a value is passed to this function, it changes it permanantly in the
database and for the lifetime of the program overrides anything that might
be in the config file.

=cut

sub helpvisible {
	my $class=shift;
	$config->{helpvisible}=$_[0] if @_;
	return $config->{helpvisible} if exists $config->{helpvisible};

	my $ret='true';
	my $question=Debconf::Question->get('debconf/helpvisible');
	if ($question) {
		return $question->value || $ret;
	}
	return $ret;
}

=item showold

If true, then old questions the user has already seen are shown to them again.
A value is pulled out of the config file or database if possible, otherwise a
default of false is used.

If a value is passed to this function, it changes it temporarily (for
the lifetime of the program) to override what's in the database or config
file.

=cut

sub showold {
	my $class=shift;
	$config->{showold}=shift if @_;
	return $config->{showold} if exists $config->{showold};
	
	my $ret='false';
	my $question=Debconf::Question->get('debconf/showold');
	if ($question) {
		$ret=$question->value || $ret;
	}
	return $ret;
}

=item debug

Returns debconf's debug regex. This is pulled out of the config file,
and may be overridden by DEBCONF_DEBUG in the environment.

=cut

sub debug {
	my $class=shift;
	return $ENV{DEBCONF_DEBUG} if exists $ENV{DEBCONF_DEBUG};
	return $config->{debug} if exists $config->{debug};
	return '';
}

=item admin_email

Returns an email address to use to send notes to. This is pulled out of the
config file, and may be overridden by the DEBCONF_ADMIN_MAIL environment
variable. If neither is set, it defaults to root.

=cut

sub admin_mail {
	my $class=shift;
	return $ENV{DEBCONF_ADMIN_EMAIL} if exists $ENV{DEBCONF_ADMIN_EMAIL};
	return $config->{admin_email} if exists $config->{admin_email};
	return 'root';
}

=back

=head1 FIELDS

Other fields can be accessed and set by calling class methods.

=cut

sub AUTOLOAD {
	(my $field = our $AUTOLOAD) =~ s/.*://;
	my $class=shift;
	
	return $config->{$field}=shift if @_;
	return $config->{$field} if defined $config->{$field};
	return '';
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
