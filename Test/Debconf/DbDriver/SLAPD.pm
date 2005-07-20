package Test::Debconf::DbDriver::SLAPD;
use strict;

use Debconf::Gettext;

use fields qw(server port dir conf ldif pidfile);

sub new {
	my Test::Debconf::DbDriver::SLAPD $self = shift;
	unless (ref $self) {
		$self = fields::new($self);
	}
	$self->{server} = shift;
	$self->{port} = shift;
	my $base_dir = shift;
	$self->{dir} = "$base_dir/slapd";

	$self->{conf} = "$self->{dir}/slapd.conf";
	$self->{ldif} = "$self->{dir}/ldap.ldif";
	$self->{pidfile} = "/tmp/slapd.pid";

	return $self;
}

sub slapd_start{
	my $self = shift;

		
#	print "beg slapd_start\n";
	# be sure that we have no residues before starting new test 
	$self->slapd_stop();

	system("mkdir -p $self->{dir}") == 0
		or die "Can not create tmp slapd data directory";

	$self->build_slapd_conf();
	$self->build_ldap_ldif();

	#
	# start local slapd daemon for testing
	#
	my $slapdbin = '/usr/sbin/slapd';
	my $slapaddbin = '/usr/sbin/slapadd';

	# is there slapd installed?
	if (! -x $slapdbin) {
		die "Unable to find $slapdbin, is slapd package installed ?"; 
	}

	system("$slapdbin -s LOG_DEBUG -f $self->{conf} -h ldap://$self->{server}:$self->{port}") == 0
		or die "Error in slapd call";
	system("$slapaddbin -f $self->{conf} -l $self->{ldif}") == 0
		or die "Error in slapadd call";

#	print "end slapd_start\n";
}

# kill slapd daemon and delete sldap data files
sub slapd_stop {
	my $self = shift;
	my $dir = $self->{dir};
	my $pf = "/tmp/slapd.pid";

#	print "beg slapd_stop\n";

	if ( -f $pf) {
#		print $pf;
		open(PIDFILE, $self->{pidfile}) or die "Can not open file: $pf";
		my $pid = <PIDFILE>;
		close PIDFILE;
		my $cnt = kill 'TERM',$pid;
		sleep 1;
#		print $cnt;
#		system("rm $pf") == 0
#		    or die "Can not delete file: $pf";
	}
	if ( -f $self->{conf}) {
		system("rm $self->{conf}") == 0
		    or die "Can not delete file: $self->{conf}";
	}
	if ( -f $self->{ldif}) {
		system("rm $self->{ldif}") == 0
		    or die "Can not delete file: $self->{ldif}";
	}
	system("rm -f $self->{dir}/*.dbb") == 0
	    or die "Can not delete .dbb files";
	system("rm -rf $self->{dir}") == 0
	    or die "Can not delete .dbb files";

#	print "end slapd_stop\n";
}

sub build_slapd_conf {
	my $self = shift;

	open(SLAPD_CONF, ">$self->{dir}/slapd.conf");
	print SLAPD_CONF gettext(<<EOF);
# This is the main ldapd configuration file. See slapd.conf(5) for more
# info on the configuration options.

modulepath      /usr/lib/ldap
moduleload      back_ldbm

# Schema and objectClass definitions
include         /etc/ldap/schema/core.schema
include         doc/debconf.schema

# Schema check allows for forcing entries to
# match schemas for their objectClasses's
schemacheck     on

# Where the pid file is put. The init.d script
# will not stop the server if you change this.
pidfile         $self->{pidfile}

# List of arguments that were passed to the server
argsfile        $self-{dir}/slapd.args

# Where to store the replica logs
replogfile	$self->{dir}/replog

# Read slapd.conf(5) for possible values
loglevel        0

#######################################################################
# ldbm database definitions
#######################################################################

# The backend type, ldbm, is the default standard
database        ldbm

# The base of your directory
suffix          "dc=debian,dc=org"

# Where the database file are physically stored
directory       "$self->{dir}"

# Indexing options
index objectClass eq

# Save the time that the entry gets modified
lastmod on

# The admin dn has full write access
access to *
        by dn="cn=admin,dc=debian,dc=org" write
        by * read

EOF

	close OUTFILE;
}

sub build_ldap_ldif {
	my $self = shift;

	open(OUTFILE, ">$self->{dir}/ldap.ldif");
	print OUTFILE gettext(<<EOF);
dn: cn=admin,dc=debian,dc=org
objectClass: organizationalRole
objectClass: simpleSecurityObject
cn: admin
description: LDAP administrator
userPassword: debian

dn: cn=debconf,dc=debian,dc=org
objectClass: applicationProcess
cn: debconf

EOF

close OUTFILE;
}

1;
