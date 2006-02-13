#!/usr/bin/perl -w
# Copyright (C) 2002 Matthew Palmer.

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

=back

=cut

use fields qw(server port basedn binddn bindpasswd exists);

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
	my $ds = Net::LDAP->new($this->{server}, port => $this->{port}, version => 3);
	if (! $ds) {
		$this->error("Unable to connect to LDAP server");
		return; # if not fatal, give up anyway
	}
	
	# Check for anon bind
	my $rv = "";
	if (!($this->{binddn} && $this->{bindpasswd})) {
		debug "db $this->{name}" => "binding anonymously; hope that's OK";
		$rv = $ds->bind;
	} else {
		debug "db $this->{name}" => "binding as $this->{binddn}";
		$rv = $ds->bind($this->{binddn}, password => $this->{bindpasswd});
	}
	if ($rv->code) {
		$this->error("Bind Failed: ".$rv->error);
	}
	
	return $ds;
}

=head2 init

On initialization, connect to the directory, read all of the debconf data
into the cache, and close off the connection again.

=cut

sub init {
	my $this = shift;

	$this->SUPER::init(@_);
	
	debug "db $this->{name}" => "getting database data";
	my $ds=$this->binddb;
	return unless $ds;
	my $data = $ds->search(base => $this->{basedn}, sizelimit => 0, timelimit => 0, filter => "(objectclass=debconfDbEntry)");
	if ($data->code) {
		$this->error("Search failed: ".$data->error);
	}
		
	# Every language does LDAP search() returns fairly similarly.  Perl's
	# modus is documented in Net::LDAP::Search, for those interested.
	my $records = $data->as_struct();
	debug "db $this->{name}" => "Read ".$data->count()." entries";	

	# A record of all the existing entries in the DB so we know which
	# ones need to added, and which modified
	$this->{exists} = {};

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
			debug "db $this->{name}" => "Setting data for $attr";
			my $values = $entry->{$attr};
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
	
	# Having done all of that, all that remains is to clean up.
	$ds->unbind;
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
	
	my $ds=$this->binddb;
	return unless $ds;

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
		
		foreach my $field (keys %{$data{fields}}) {
			# skip empty fields exept value field
			next if ($data{fields}->{$field} eq '' && 
				 !($field eq 'value'));
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
			$rv = $ds->modify($entry_dn, replace => \%modify_data);
		} else {
			$rv = $ds->add($entry_dn, attrs => $add_data);
		}
		if ($rv->code) {
			$this->error("Modify failed: ".$rv->error);
		}
	}

	$ds->unbind();

	$this->SUPER::shutdown(@_);
}
				
# Empty routine

sub load {}

=sub remove

Called by Cache::shutdown, nothing to do because already done in LDAP::shutdown

=cut

sub remove {
	return 1;
}

=sub save

Called by Cache::shutdown, nothing to do because already done in LDAP::shutdown

=cut

sub save {
	return 1;
}

=head1 AUTHOR

Matthew Palmer <mpalmer@ieee.org>

=cut

1
