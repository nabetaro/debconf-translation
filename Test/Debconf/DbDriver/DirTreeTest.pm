#constants

=head1 NAME

Test::Debconf::DbDriver::DirTreeTest - DirTree driver class test

=cut

package Test::Debconf::DbDriver::DirTreeTest;
use strict;
use File::Temp;
use Debconf::DbDriver::DirTree;
use Test::Unit::TestSuite;
use base qw(Test::Debconf::DbDriver::CommonTest);

sub new {
	my $self = shift()->SUPER::new(@_);
	return $self;
}

sub new_driver {
	my $self = shift;

	my %params = (
		name => "dirtreedb",
		directory => $self->{tmpdir},
	);

	$self->{driver} = Debconf::DbDriver::DirTree->new(%params);
}

sub set_up {
	my $self = shift;
	
	$self->{tmpdir} = File::Temp->tempdir('dirtreedb-XXXX', DIR => '/tmp');
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
