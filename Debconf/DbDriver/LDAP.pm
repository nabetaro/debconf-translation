#!/usr/bin/perl -w
# Copyright (C) 2002 Matthew Palmer.
# Copyright (C) 2007-2008 Davor Ocelic.

=head1 NAME

Debconf::DbDriver::LDAP - access (config) database in an LDAP directory

=cut

package Debconf::DbDriver::LDAP;
use strict;
use Debconf::Log qw(:all);
use Net::LDAP;
use base 'Debconf::DbDriver::Cache';

=head1 DESCRIPTION

A Debconf database driver to access an LDAP directory for configuration
data.  It reads all the relevant entries from the directory server on
startup (which can take a little while) however this cost is less than the
equivalent time if data accesses were done piecemeal.

Due to the nature of the beast, LDAP directories should typically be
accessed in read-only mode.  This is because multiple accesses can take
place, and it's generally better for data consistency if nobody tries to
modify the data while this is happening.  Of course, write access is
supported for those cases where you do want to update the config data in the
directory.

=head1 FIELDS

=over 4

=item server

The host name or IP address of an LDAP server to connect to.

=item port

The port on which to connect to the LDAP server.  If none is given, the
default is used.

=item basedn

The DN under which all config items will be stored.  Each config item will
be assumed to live in a DN of cn=<item name>,<Base DN>.  If this structure
is not followed, all bets are off.

=item binddn

The DN to bind to the directory as.  Anonymous bind will be used if none is
specified.

=item bindpasswd

The password to use in an authenticated bind (used with binddn, above).  If
not specified, anonymous bind will be used.

This option should not be used in the general case.  Anonymous binding
should be sufficient most of the time for read-only access.  Specifying a
bind DN and password should be reserved for the occasional case where you
wish to update the debconf configuration data.

=item keybykey

Enable access to individual LDAP entries, instead of fetching them
all at once in the beginning. This is very useful if you want to monitor your
LDAP logs for specific debconf keys requested. In this way, you could also
write custom handling code on the LDAP server part.

Note that when this option is enabled, the connection to the LDAP server
is kept active during the whole Debconf run. This is a little different
from the all-in-one behavior where two brief connections are made to LDAP;
in the beginning to retrieve all the entries, and in the end to save 
eventual changes.

=back

=cut

use fields qw(server port basedn binddn bindpasswd exists keybykey ds accept_attribute reject_attribute);

=head1 METHODS

=head2 binddb

Connect to the LDAP server, and bind to the DN. Retuns a Net::LDAP object.

=cut

sub binddb {
	my $this=shift;

	# Check for required options
	$this->error("No server specified") unless exists $this->{server};
	$this->error("No Base DN specified") unless exists $this->{basedn};
	
	# Set up other defaults
	$this->{binddn} = "" unless exists $this->{binddn};
	# XXX This will need to handle SSL when we support it
	$this->{port} = 389 unless exists $this->{port};
	
	debug "db $this->{name}" => "talking to $this->{server}, data under $this->{basedn}";

	# Whee, LDAP away!  Net::LDAP tells us about all these methods.
	$this->{ds} = Net::LDAP->new($this->{server}, port => $this->{port}, version => 3);
	if (! $this->{ds}) {
		$this->error("Unable to connect to LDAP server");
		return; # if not fatal, give up anyway
	}
	
	# Check for anon bind
	my $rv = "";
	if (!($this->{binddn} && $this->{bindpasswd})) {
		debug "db $this->{name}" => "binding anonymously; hope that's OK";
		$rv = $this->{ds}->bind;
	} else {
		debug "db $this->{name}" => "binding as $this->{binddn}";
		$rv = $this->{ds}->bind($this->{binddn}, password => $this->{bindpasswd});
	}
	if ($rv->code) {
		$this->error("Bind Failed: ".$rv->error);
	}
	
	return $this->{ds};
}

=head2 init

On initialization, connect to the directory, read all of the debconf data
into the cache, and close off the connection again.

If KeyByKey is enabled, then skip the complete data load and only retrieve
few keys required by debconf.

=cut

sub init {
	my $this = shift;

	$this->SUPER::init(@_);

	$this->binddb;
	return unless $this->{ds};

	# A record of all the existing entries in the DB so we know which
	# ones need to added, and which modified
	$this->{exists} = {};
	
	if ($this->{keybykey}) {
		debug "db $this->{name}" => "will get database data key by key";
	}
	else {
		debug "db $this->{name}" => "getting database data";
		my $data = $this->{ds}->search(base => $this->{basedn}, sizelimit => 0, timelimit => 0, filter => "(objectclass=debconfDbEntry)");
		if ($data->code) {
			$this->error("Search failed: ".$data->error);
		}
			
		my $records = $data->as_struct();
		debug "db $this->{name}" => "Read ".$data->count()." entries";	
	
		$this->parse_records($records);
	
		$this->{ds}->unbind;
	}
}

=head2 shutdown

Save the dirty entries back to the LDAP server.

=cut

sub shutdown
{
	my $this = shift;
	
	return if $this->{readonly};
	
	if (grep $this->{dirty}->{$_}, keys %{$this->{cache}}) {
		debug "db $this->{name}" => "saving changes";
	} else {
		debug "db $this->{name}" => "no database changes, not saving";
		return 1;
	}
	
	unless ($this->{keybykey}) {
		$this->binddb;
		return unless $this->{ds};
	}

	foreach my $item (keys %{$this->{cache}}) {
		next unless defined $this->{cache}->{$item};  # skip deleted
		next unless $this->{dirty}->{$item};	# skip unchanged
		# These characters must be quoted in the DN
		(my $entry_cn = $item) =~ s/([,+="<>#;])/\\$1/g;
		my $entry_dn = "cn=$entry_cn,$this->{basedn}";
		debug "db $this->{name}" => "writing out to $entry_dn";
		
		my %data = %{$this->{cache}->{$item}};
		my %modify_data;
		my $add_data = [ 'objectclass' => 'top',
				'objectclass' => 'debconfdbentry',
				'cn' => $item
		];

		# Perform generic replacement in style of:
		# extended_description -> extendedDescription
		my @fields = keys %{$data{fields}};
		foreach my $field (@fields) {
			my $ldapname = $field;
			if ( $ldapname =~ s/_(\w)/uc($1)/ge ) {
				$data{fields}->{$ldapname} =  $data{fields}->{$field};
				delete $data{fields}->{$field};
			}
		}
		
		foreach my $field (keys %{$data{fields}}) {
			# skip empty fields exept value field
			next if ($data{fields}->{$field} eq '' && 
				 !($field eq 'value'));
			if ((exists $this->{accept_attribute} &&
				 $field !~ /$this->{accept_attribute}/) or
				(exists $this->{reject_attribute} &&
				 $field =~ /$this->{reject_attribute}/)) {
				debug "db $item" => "reject $field";
				next;
			}

 			$modify_data{$field}=$data{fields}->{$field};
			push(@{$add_data}, $field);
			push(@{$add_data}, $data{fields}->{$field});
		}

		my @owners = keys %{$data{owners}};
		debug "db $this->{name}" => "owners is ".join("  ", @owners);
		$modify_data{owners} = \@owners;
		push(@{$add_data}, 'owners');
		push(@{$add_data}, \@owners);
		
		my @flags = grep { $data{flags}->{$_} eq 'true' } keys %{$data{flags}};
		if (@flags) {
			$modify_data{flags} = \@flags;
			push(@{$add_data}, 'flags');
			push(@{$add_data}, \@flags);
		}

		$modify_data{variables} = [];
		foreach my $var (keys %{$data{variables}}) {
			my $variable = "$var=$data{variables}->{$var}";
			push (@{$modify_data{variables}}, $variable);
			push(@{$add_data}, 'variables');
			push(@{$add_data}, $variable);
		}
		
		my $rv="";
		if ($this->{exists}->{$item}) {
			$rv = $this->{ds}->modify($entry_dn, replace => \%modify_data);
		} else {
			$rv = $this->{ds}->add($entry_dn, attrs => $add_data);
		}
		if ($rv->code) {
			$this->error("Modify failed: ".$rv->error);
		}
	}

	$this->{ds}->unbind();

	$this->SUPER::shutdown(@_);
}

=head2 load 

Empty routine for all-in-one db fetch, but does some actual
work for individual keys retrieval.

=cut

sub load {
	my $this = shift;
	return unless $this->{keybykey};
	my $entry_cn = shift;

	my $records = $this->get_key($entry_cn);
	return unless $records;
		
	debug "db $this->{name}" => "Read entry for $entry_cn";

	$this->parse_records($records);
}

=head2 remove

Called by Cache::shutdown, nothing to do because already done in LDAP::shutdown

=cut

sub remove {
	return 1;
}

=head2 save

Called by Cache::shutdown, nothing to do because already done in LDAP::shutdown

=cut

sub save {
	return 1;
}

=head2 get_key

Retrieve individual key from LDAP db.
The function is a no-op if KeyByKey is disabled.
Returns entry->as_struct if found, undef otherwise.

=cut

sub get_key {
	my $this = shift;
	return unless $this->{keybykey};
	my $entry_cn = shift;

	my $data = $this->{ds}->search(
		base => 'cn=' . $entry_cn . ',' . $this->{basedn},
		sizelimit => 0,
		timelimit => 0,
		filter => "(objectclass=debconfDbEntry)");

	if ($data->code) {
		$this->error("Search failed: ".$data->error);
	}

	return unless $data->entries;
	$data->as_struct();
}

# Parse struct data (such as one returned by get_key())
# into internal hash/cache representation
sub parse_records {
	my $this = shift;
	my $records = shift;

	# This is a rather great honking loop, but it's quite simply a nested
	# bunch of loops iterating through every DN, attribute, and value in
	# the returned set (the complete debconf database) and storing it in
	# a format which the cache driver hopefully understands.
	foreach my $dn (keys %{$records}) {
		my $entry = $records->{$dn};
		debug "db $this->{name}" => "Reading data from $dn";
		my %ret = (owners => {},
			fields => {},
			variables => {},
			flags => {},
		);
		my $name = "";

		foreach my $attr (keys %{$entry}) {
			if ($attr eq 'objectclass') {
				next;
			}
			my $values = $entry->{$attr};

			# Perform generic replacement in style of:
			# extendedDescription -> extended_description
			$attr =~ s/([a-z])([A-Z])/$1.'_'.lc($2)/ge;

			debug "db $this->{name}" => "Setting data for $attr";
			foreach my $val (@{$values}) {
				debug "db $this->{name}" => "$attr = $val";
				if ($attr eq 'owners') {
					$ret{owners}->{$val}=1;
				} elsif ($attr eq 'flags') {
					$ret{flags}->{$val}='true';
				} elsif ($attr eq 'cn') {
					$name = $val;
				} elsif ($attr eq 'variables') {
					my ($var, $value)=split(/\s*=\s*/, $val, 2);
					$ret{variables}->{$var}=$value;
				} else {
					$val=~s/\\n/\n/g;
					$ret{fields}->{$attr}=$val;
				}
			}
		}

		$this->{cache}->{$name} = \%ret;
		$this->{exists}->{$name} = 1;
	}
}

=head1 AUTHOR

Matthew Palmer <mpalmer@ieee.org>

Davor Ocelic <docelic@spinlocksolutions.com>

=cut

1
