package Test::AllTests;

use strict;
use Test::Unit::TestSuite;
use Test::CopyDBTest;
use Test::Debconf::DbDriver::DirTreeTest;
use Test::Debconf::DbDriver::FileTest;
use Test::Debconf::DbDriver::LDAPTest;

sub suite {
	my $class = shift;
    
	# create an empty suite
	my $suite = Test::Unit::TestSuite->empty_new("All Tests Suite");
    
	# add CopyDB test suite
	$suite->add_test(Test::CopyDBTest->suite());

	# add DirTree test suite
	$suite->add_test(Test::Debconf::DbDriver::DirTreeTest->suite());

	# add File test suite
	$suite->add_test(Test::Debconf::DbDriver::FileTest->suite());

	# add LDAP test suite
	no strict 'refs';
	my $ldapsuite;
	my $ldapsuite_method = \&{"Test::Debconf::DbDriver::LDAPTest::suite"};
	eval {
		$ldapsuite = $ldapsuite_method->();
	};
	$suite->add_test($ldapsuite);
    
	# add your test suite or test case
	# extract suite by way of suite method and add
	#$suite->add_test(MyModule::Suite->suite());
	
	# get and add another existing suite
	#$suite->add_test(Test::Unit::TestSuite->new("MyModule::TestCase"));


	# return the suite built
	return $suite;
}

1;
