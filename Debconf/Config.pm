#!/usr/bin/perl -w

=head1 NAME

Debconf::Config - Debconf meta-configuration module

=cut

package Debconf::Config;
use strict;
use Debconf::Question;
use Debconf::Gettext;
use Debconf::Priority qw(priority_valid priority_list);
use Debconf::Log qw(warn);
use Debconf::Db;

use fields qw(config templates frontend frontend_forced priority terse reshow
              admin_email log debug nowarnings smileys sigils
              noninteractive_seen c_values);
our $config=fields::new('Debconf::Config');

our @config_files=("/etc/debconf.conf", "/usr/share/debconf/debconf.conf");
if ($ENV{DEBCONF_SYSTEMRC}) {
	unshift @config_files, $ENV{DEBCONF_SYSTEMRC};
} else {
	# I don't use $ENV{HOME} because it can be a bit untrustworthy if
	# set by programs like sudo, and that proved to be confusing
	unshift @config_files, ((getpwuid($>))[7])."/.debconfrc";
}
	   
=head1 DESCRIPTION

This package holds configuration values for debconf. It supplies defaults,
and allows them to be overridden by values from the command line, the 
environment, the config file, and values pulled out of the debconf database.

=head1 METHODS

=over 4

=item load

This class method reads and parses a config file. The config file format is
a series of stanzas; the first stanza configures debconf as a whole, and
then each of the rest sets up a database driver. This lacks the glorious
nested bindish beauty of Wichert's original idea, but it captures the
essence of it. It will load from a set of standard locations unless a file
to load is specified as the first parameter.

If a hash of parameters are passed, those parameters are used as the defaults
for *every* database driver that is loaded up. Practically, setting 
(readonly => "true") is the only use of this.

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
		$line=~s/^\s+//;
		$line=~s/\s+$//;
		$i++;
		my ($key, $value)=split(/\s*:\s*/, $line, 2);
		$key=~tr/-/_/;
		die "Parse error" unless defined $key and length $key;
		$hash->{lc($key)}=$value;
	}
	return $i;
}
 
# Processes an environment variable that encodes a reference to an existing
# db, or the parameters to set up a new db. Returns the db. Additional
# parameters will be used as defaults if a new driver is set up. At least a
# name default should always be passed. Returns the db name.
sub _env_to_driver {
	my $value=shift;
	
	my ($name, $options) = $value =~ m/^(\w+)(?:{(.*)})?$/;
	return unless $name;
	
	return $name if Debconf::DbDriver->driver($name);
	
	my %hash = @_; # defaults from params
	$hash{driver} = $name;
	
	if (defined $options) {
		# And add any other name:value name:value pairs,
		# default name is `filename' for convienence.
		foreach (split ' ', $options) {
			if (/^(\w+):(.*)/) {
				$hash{$1}=$2;
			}
			else {
				$hash{filename}=$_;
			}
		}
	}
	return Debconf::Db->makedriver(%hash)->{name};
}

sub load {
	my $class=shift;
	my $cf=shift;
	my @defaults=@_;
	
	if (! $cf) {
		for my $file (@config_files) {
			$cf=$file, last if -e $file;
		}
	}
	die "No config file found" unless $cf;

	open (DEBCONF_CONFIG, $cf) or die "$cf: $!\n";
	local $/="\n\n"; # read a stanza at a time

	# Read global options stanza.
	1 until _hashify(<DEBCONF_CONFIG>, $config) || eof DEBCONF_CONFIG;

	# Verify that all options are sane.
	if (! exists $config->{config}) {
		print STDERR "debconf: ".gettext("Config database not specified in config file.")."\n";
		exit(1);
	}
	if (! exists $config->{templates}) {
		print STDERR "debconf: ".gettext("Template database not specified in config file.")."\n";
		exit(1);
	}

	if (exists $config->{sigils} || exists $config->{smileys}) {
		print STDERR "debconf: ".gettext("The Sigils and Smileys options in the config file are no longer used. Please remove them.")."\n";
	}

	# Now read in each database driver, and set it up.
	while (<DEBCONF_CONFIG>) {
		my %config=(@defaults);
		if (exists $ENV{DEBCONF_DB_REPLACE}) {
			$config{readonly} = "true";
		}
		next unless _hashify($_, \%config);
		eval {
			Debconf::Db->makedriver(%config);
		};
		if ($@) {
			print STDERR "debconf: ".sprintf(gettext("Problem setting up the database defined by stanza %s of %s."),$., $cf)."\n";
			die $@;
		}
	}
	close DEBCONF_CONFIG;

	# DEBCONF_DB_REPLACE bypasses the normal databases. We do still need
	# to set up the normal databases anyway so that the template
	# database is available, but we load them all read-only above.
	if (exists $ENV{DEBCONF_DB_REPLACE}) {
		$config->{config} = _env_to_driver($ENV{DEBCONF_DB_REPLACE},
			name => "_ENV_REPLACE");
		# Unfortunately a read-only template database isn't always
		# good enough, so we need to stack a throwaway one in front
		# of it just in case anything tries to register new
		# templates. There is no provision yet for keeping this
		# database around after debconf exits.
		Debconf::Db->makedriver(
			driver => "Pipe",
			name => "_ENV_REPLACE_templates",
			infd => "none",
			outfd => "none",
		);
		my @template_stack = ("_ENV_REPLACE_templates", $config->{templates});
		Debconf::Db->makedriver(
			driver => "Stack",
			name => "_ENV_stack_templates",
			stack => join(", ", @template_stack),
		);
		$config->{templates} = "_ENV_stack_templates";
	}

	# Allow environment overriding of primary database driver
	my @finalstack = ($config->{config});
	if (exists $ENV{DEBCONF_DB_OVERRIDE}) {
		unshift @finalstack, _env_to_driver($ENV{DEBCONF_DB_OVERRIDE},
			name => "_ENV_OVERRIDE");
	}
	if (exists $ENV{DEBCONF_DB_FALLBACK}) {
		push @finalstack, _env_to_driver($ENV{DEBCONF_DB_FALLBACK},
			name => "_ENV_FALLBACK",
			readonly => "true");
	}
	if (@finalstack > 1) {
		Debconf::Db->makedriver(
			driver => "Stack",
			name => "_ENV_stack",
			stack  => join(", ", @finalstack),
		);
		$config->{config} = "_ENV_stack";
	}
}

=item getopt

This class method parses command line options in @ARGV with GetOptions from
Getopt::Long.  Many meta configuration items can be overridden with command
line options.

The first parameter should be basic usage text for the program in
question. Usage text for the globally supported options will be prepended
to this if usage help must be printed.

If any additonal parameters are passed to this function, they are also
passed to GetOptions. This can be used to handle additional options.

=cut

sub getopt {
	my $class=shift;
	my $usage=shift;

	my $showusage=sub { # closure
		print STDERR $usage."\n";
		print STDERR gettext(<<EOF);
  -f,  --frontend		Specify debconf frontend to use.
  -p,  --priority		Specify minimum priority question to show.
       --terse			Enable terse mode.
EOF
		exit 1;
	};

	# don't load big Getopt::Long unless really necessary.
	return unless grep { $_ =~ /^-/ } @ARGV;
	
	require Getopt::Long;
	Getopt::Long::Configure('bundling');
	Getopt::Long::GetOptions(
		'frontend|f=s',	sub { shift; $class->frontend(shift); $config->frontend_forced(1) },
		'priority|p=s',	sub { shift; $class->priority(shift) },
		'terse',	sub { $config->{terse} = 'true' },
		'help|h',	$showusage,
		@_,
	) || $showusage->();
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
	
	my $ret='dialog';
	my $question=Debconf::Question->get('debconf/frontend');
	if ($question) {
		$ret=lcfirst($question->value) || $ret;
	}
	return $ret;
}

=item frontend_forced

Whether the frontend was forced set on the command line or in the
environment.

=cut

sub frontend_forced {
	my ($class, $val) = @_;
	$config->{frontend_forced} = $val
		if defined $val || exists $ENV{DEBIAN_FRONTEND};
	return $config->{frontend_forced} ? 1 : 0;
}

=item priority

The lowest priority of questions you want to see. Looks at first the value
of DEBIAN_PRIORITY, second the config file, third the database, and if all
of those fail, defaults to "high".

If a value is passed to this function, it changes it temporarily (for
the lifetime of the program) to override what's in the database or config
file.

=cut

sub priority {
	my $class=shift;
	return $ENV{DEBIAN_PRIORITY} if exists $ENV{DEBIAN_PRIORITY};
	if (@_) {
		my $newpri=shift;
		if (! priority_valid($newpri)) {
			warn(sprintf(gettext("Ignoring invalid priority \"%s\""), $newpri));
			warn(sprintf(gettext("Valid priorities are: %s"), join(" ", priority_list())));
		}
		else {
			$config->{priority}=$newpri;
		}
	}
	return $config->{priority} if exists $config->{priority};

	my $ret='high';
	my $question=Debconf::Question->get('debconf/priority');
	if ($question) {
		$ret=$question->value || $ret;
	}
	return $ret;
}

=item terse

The behavior in terse mode varies by frontend. Changes to terse mode are
not persistant across debconf invocations.

=cut

sub terse {
	my $class=shift;
	return $ENV{DEBCONF_TERSE} if exists $ENV{DEBCONF_TERSE};
	$config->{terse}=$_[0] if @_;
	return $config->{terse} if exists $config->{terse};
	return 'false';
}

=item nowarnings

Set to disable warnings.

=cut

sub nowarnings {
	my $class=shift;
	return $ENV{DEBCONF_NOWARNINGS} if exists $ENV{DEBCONF_NOWARNINGS};
	$config->{nowarnings}=$_[0] if @_;
	return $config->{nowarnings} if exists $config->{nowarnings};
	return 'false';
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

sub admin_email {
	my $class=shift;
	return $ENV{DEBCONF_ADMIN_EMAIL} if exists $ENV{DEBCONF_ADMIN_EMAIL};
	return $config->{admin_email} if exists $config->{admin_email};
	return 'root';
}

=item noninteractive_seen

Set to cause the seen flag to be set for questions asked in the
noninteractive frontend.

=cut

sub noninteractive_seen {
	my $class=shift;
	return $ENV{DEBCONF_NONINTERACTIVE_SEEN} if exists $ENV{DEBCONF_NONINTERACTIVE_SEEN};
	return $config->{noninteractive_seen} if exists $config->{noninteractive_seen};
	return 'false';
}

=item c_values

Set to true to display "coded" values from Choices-C fields instead of the
descriptive values from other fields for select and multiselect templates.

=cut

sub c_values {
	my $class=shift;
	return $ENV{DEBCONF_C_VALUES} if exists $ENV{DEBCONF_C_VALUES};
	return $config->{c_values} if exists $config->{c_values};
	return 'false';
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

Joey Hess <joeyh@debian.org>

=cut

1
