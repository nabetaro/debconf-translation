# constants
my $_SERVER = 'localhost';
my $_PORT = '9009';
my $_LDAPDIR = 'Test/Debconf/DbDriver/ldap';

package LDAPTestSetup;

use strict;
use base qw(Test::Unit::Setup);

sub set_up{
	my $self = shift();

	# be sure that we have no residues before starting new test 
	$self->slapd_clean();

	#
	# start local slapd daemon for testing
	#
	my $conf = "$_LDAPDIR/slapd.conf";
	my $ldif = "$_LDAPDIR/ldap.ldif";
	my $slapdbin = '/usr/sbin/slapd';
	my $slapaddbin = '/usr/sbin/slapadd';

	# is there slapd installed?
	if (! -x $slapdbin) {
		die "Unable to find $slapdbin, is slapd package installed ?"; 
	}

	system("$slapdbin -f $conf -h ldap://$_SERVER:$_PORT") == 0
		or die "Error in slapd call";
	system("$slapaddbin -f $conf -l $ldif") == 0
		or die "Error in slapadd call";
}

sub tear_down{
	my $self = shift();
    
	$self->slapd_clean();
}

# kill slapd daemon and delete sldap data files
sub slapd_clean {
	my $self = shift;

	my $pf = "$_LDAPDIR/slapd.pid";
	if ( -f $pf) {
		open(PIDFILE, $pf) or die "Can not open file: $pf";
		my $pid = <PIDFILE>;
		kill 'TERM',$pid;
		close PIDFILE;
	}
	system("rm -f $_LDAPDIR/*.dbb $_LDAPDIR/slapd.args $_LDAPDIR/slapd.pid $_LDAPDIR/replog*") == 0
		or die "Can not delete slapd data files";

}

=head1 NAME

  Test::Debconf::DbDriver::LDAPTest - LDAP driver class test

=cut

package Test::Debconf::DbDriver::LDAPTest;
use strict;
use Debconf::DbDriver::LDAP;
use Test::Unit::TestSuite;
use FreezeThaw qw(cmpStr);
use base qw(Test::Debconf::DbDriver::CommonTest);

sub new {
	my $self = shift()->SUPER::new(@_);
	return $self;
}

sub new_driver {
	my $self = shift;

	#
	# start LDAP driver
	#

	my %params = (
		name => "ldapdb",
		server => "$_SERVER",
		port => "$_PORT",
		basedn => "cn=debconf,dc=debian,dc=org",
		binddn => "cn=admin,dc=debian,dc=org",
		bindpasswd => "debian",
	);
    
	$self->{driver} = Debconf::DbDriver::LDAP->new(%params);
}

sub shutdown_driver {
	my $self = shift;

	$self->{driver}->shutdown();
}

sub set_up {
	my $self = shift;
	
	$self->new_driver();
}

sub tear_down {
	my $self = shift;

	$self->shutdown_driver();
}

sub suite {
	my $self = shift;

	my $testsuite = Test::Unit::TestSuite->new(__PACKAGE__);
	my $wrapper = LDAPTestSetup->new($testsuite);
    
	return $wrapper;
}

1;
