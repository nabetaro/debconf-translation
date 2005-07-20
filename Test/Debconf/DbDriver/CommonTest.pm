package Test::Debconf::DbDriver::CommonTest;
use strict;
use FreezeThaw qw(cmpStr freeze);
use base qw(Test::Unit::TestCase);

sub new {
	my $self = shift()->SUPER::new(@_);
	return $self;
}

=head1 METHODS

This is the list of common tests used to validate drivers.
'test_item_*' methods create an item , put it on db, reload it from db and
test if the result is the same of the original.

=head2 test_item_1

    Name : debconf-test/test_1
    Owners : debconf-test, toto

=cut

sub test_item_1 {
	my $self = shift;
	$self->{testname} = 'test_item_1';

	# item for testing
	$self->{item} = { 
		name => 'debconf-test/test_1',
		entry => { 
			owners => { 'debconf-test' => 1, toto => 1 },
			fields => {},
			variables => {},
			flags => {},
		}
	}; 

	$self->go_test_item();
}

=head2 test_item_2

    Name : debconf-test/test_2
    Owners : debconf_test
    Value : <EMPTY> 

=cut

sub test_item_2 {
	my $self = shift;
	$self->{testname} = 'test_item_2';

	# item for testing
	$self->{item} = { 
		name => 'debconf-test/test_2',
		entry => { 
			owners => { 'debconf_test' => 1 },
			fields => { value => '' },
			variables => {},
			flags => {},
		} 
	}; 

	$self->go_test_item();
}

=head2 test_item_3

    Name : debconf-test/test_3
    Owners : debconf
    Variables : countries = <EMPTY> 

=cut

sub test_item_3 {
	my $self = shift;
	$self->{testname} = 'test_item_3';

	# item for testing
	$self->{item} = { 
		name => 'debconf-test/test_3',
		entry => { 
			owners => { 'debconf' => 1 },
			fields => {},
			variables => { countries => ''},
			flags => {},
		} 
	};

	$self->go_test_item();
}

=head2 test_item_4

    Name : debconf-test/test_4
    Owners : debconf
    Flags : seen 

=cut

sub test_item_4 {
	my $self = shift;
	$self->{testname} = 'test_item_4';

	# item for testing
	$self->{item} = { 
		name => 'debconf-test/test_4',
		entry => { 
			owners => { 'debconf' => 1 },
			fields => {},
			variables => {},
			flags => { seen => 'true'},
		} 
	}; 

	$self->go_test_item();
}

sub test_shutdown {
	my $self = shift;
	$self->{testname} = 'test_shutdown';

	# item for testing
	my $item = { 
		name => 'debconf-test/test_shutdown',
		entry => { 
			owners => { 'debconf' => 1 },
			fields => {},
			variables => {},
			flags => { seen => 'true'},
		} 
	}; 

	$self->add_item($item, 'debconf',$self->{driver});

	$self->{driver}->shutdown();

	 # verify if item is in cache and not in a dirty state
	$self->assert(defined $self->{driver}->cachedata($item->{name}),
	              'item not defined in cache'); 
	# verify that item is not in a dirty state
	$self->assert($self->{driver}->{dirty}->{$item->{name}} == 0,
		      'item still in a dirty state in cache');

}

sub go_test_item {
	my $self = shift;
	my $itemname = $self->{item}->{name};
	my $entry = $self->{item}->{entry};
    
	# add item in the cache
	$self->{driver}->cacheadd($itemname, $entry); 
	# set item in dirty state => it will be saved in database
	$self->{driver}->{dirty}->{$itemname}=1;

	# save item to database and reload it from database
	$self->reconnectdb();

	my $entry_from_db = $self->{driver}->cached($itemname);

	my $result = cmpStr($entry, $entry_from_db);
	$self->assert($result == 0, 
	              'item saved in database differs from the original item'); 
}

sub reconnectdb {
	my $self = shift;

	# save items to database server
	$self->shutdown_driver();
	# reload same items from database server 
	$self->new_driver();
}

sub shutdown_driver {
	my $self = shift;

	$self->{driver}->shutdown();
}

sub add_item {
	my $self = shift;
	my $item = shift;
	my $owner = shift;
	my $dbdriver = shift;

	$dbdriver->addowner($item->{name}, $owner);

	foreach my $field (keys %{$item->{entry}->{fields}}) {
		$dbdriver->setfield($item->{name}, $field, $item->{entry}->{fields}->{$field});
	}
	foreach my $flag (keys %{$item->{entry}->{flags}}) {
		$dbdriver->setflag($item->{name}, $flag, $item->{entry}->{flags}->{$flag});
	}
	foreach my $variable (keys %{$item->{entry}->{variables}}) {
		$dbdriver->setvariable($item->{name}, $variable, $item->{entry}->{variables}->{$variable});
	}
}
1;
