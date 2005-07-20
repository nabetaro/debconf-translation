# constants

=head1 NAME

Test::Debconf::DbDriver::FileTest - File driver class test

=cut

package Test::Debconf::DbDriver::FileTest;
use strict;
use File::Temp;
use Debconf::DbDriver::File;
use Test::Unit::TestSuite;
use base qw(Test::Debconf::DbDriver::CommonTest);

sub new {
	my $self = shift()->SUPER::new(@_);
	return $self;
}

sub new_driver {
	my $self = shift;

	my %params = (
		name => "filedb",
		filename => $self->{tmpfile}->filename,
	);
    
	$self->{driver} = Debconf::DbDriver::File->new(%params);
}

sub set_up {
	my $self = shift;
	
	$self->{tmpfile} = new File::Temp( DIR => '/tmp');
	
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
