=head1 NAME

Test::Debconf::DbDriver::PackageDirTest - PackageDir driver class test

=cut

package Test::Debconf::DbDriver::PackageDirTest;
use strict;
use File::Temp;
use Debconf::DbDriver::PackageDir;
use Test::Unit::TestSuite;
use base qw(Test::Debconf::DbDriver::CommonTest);

sub new {
	my $self = shift()->SUPER::new(@_);
	return $self;
}

sub new_driver {
	my $self = shift;

	my %params = (
		name => "packdirdb",
		directory => $self->{tmpdir},
	);
    
	$self->{driver} = Debconf::DbDriver::PackageDir->new(%params);
}

sub set_up {
	my $self = shift;
	
	$self->{tmpdir} = File::Temp->tempdir('packdirdb-XXXX', DIR => '/tmp');
	$self->new_driver();
}

sub tear_down {
	my $self = shift;

	$self->shutdown_driver();
}

sub suite {
	my $self = shift;

	my $testsuite = Test::Unit::TestSuite->new(__PACKAGE__);
    
	return $testsuite;
}

1;
