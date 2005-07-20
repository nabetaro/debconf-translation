# constants
my $tmp_base_dir = "/tmp/debconf-test/debconf/dbdriver/ldap";
my $_SERVER = 'localhost';
my $_PORT = '9009';
my $_LDAPDIR = 'Test/Debconf/DbDriver/ldap';

package LDAPTestSetup;

use strict;
use Test::Debconf::DbDriver::SLAPD;
use base qw(Test::Unit::Setup);

sub set_up{
	my $self = shift();

	system("mkdir -p $tmp_base_dir") == 0
		or die "Can not create tmp data directory";

	$self->{slapd} = Test::Debconf::DbDriver::SLAPD->new('localhost',9009,$tmp_base_dir);
	$self->{slapd}->slapd_start();
}

sub tear_down{
	my $self = shift();
    
	$self->{slapd}->slapd_stop();
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
