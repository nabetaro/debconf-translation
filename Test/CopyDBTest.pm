my $tmp_base_dir = "/tmp/debconf-test";

package CopyDBTestSetup;

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

package Test::CopyDBTest;
use strict;
use File::Temp;
use Debconf::Config;
use Debconf::Db;
use Debconf::DbDriver::Backup;
use Debconf::Gettext;
use Debconf::Template;
use FreezeThaw qw(cmpStr freeze);
use Test::Unit::TestSuite;
use base qw(Test::Unit::TestCase);


sub new {
	my $self = shift()->SUPER::new(@_);
	return $self;
}


=head1 METHODS

This is the list of common tests used to validate debconf-copydb.
'test_item_*' methods create an item , put it on source db , copy it to dest db and
test if the result is ok and respect the pattern passed.

=cut

sub test_item_1 {
	my $self = shift;
	$self->{testname} = 'test_item_1';
	my $owner = 'debconf-test';
	my $name = "$owner/$self->{testname}";
	my $type = "note";

	Debconf::Template->new($name,$owner,$type);

	my $item = {
		name => "$name",
		entry => { 
			owners => { "$owner" => 1},
			fields => { template => "$name"},
			variables => {},
		}
	}; 

	$self->{assert} = sub {
		my $item_config_entry = shift;
		my $entry_from_db = shift;
		my $result = cmpStr($item_config_entry, $entry_from_db);
#		print "src: ",freeze($item_config_entry),"\n";
#		print "dest: ",freeze($entry_from_db),"\n";
		$self->assert($result == 0, 
			      'item saved in database differs from the original item');
	};

	@{$self->{src_db_names}} = ('configdb','dirtreedb','packdirdb','ldapdb',);
	@{$self->{dest_db_names}} = ('packdirdb','filedb','dirtreedb','ldapdb',);

	$self->{pattern} = '.*';
	$self->go_test_copy($item,$owner);
}

# Closes: #201431
sub test_201431 {
	my $self = shift;
	$self->{testname} = 'test_item_2';
	my $owner = 'passwd';
	my $name = "$owner/passwd-empty";
	my $type = "note";

	# item for testing
	Debconf::Template->new($name,$owner,$type);

	my $item = { 
		name => "$name",
		entry => { 
			owners => { "$owner" => 1},
			fields => { template => "$name"},
			flags => {},
			variables => {},
		}
	}; 

	$self->{assert} = sub {
		my $item_config_entry = shift;
		my $entry_from_db = shift;
		$self->assert_null($entry_from_db, 
			      'item saved in database differs from the original item');
	};

	@{$self->{src_db_names}} = ('configdb','dirtreedb','packdirdb','ldapdb',);
	@{$self->{dest_db_names}} = ('passwddb',);

	$self->{pattern} = '^passwd/';
	$self->go_test_copy($item, $owner);

}

sub add_item_in_db {
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

	# force to flush
	$self->db_reload();
}

sub go_test_copy {
	my $self = shift;
	my $item = shift;
	my $owner = shift;

	# test to copy item from each src databases  
	my @src_db_names = @{$self->{src_db_names}};
	foreach my $src_db_name (@src_db_names) {

		# test to copy item in all dest databases  
		my @dest_db_names = @{$self->{dest_db_names}};
		foreach my $dest_db_name (@dest_db_names) {
			
			# add item in src db
			$self->add_item_in_db($item, $owner, Debconf::DbDriver->driver($src_db_name));

			$self->copydb(Debconf::DbDriver->driver($src_db_name),
				      Debconf::DbDriver->driver($dest_db_name),
				      'file2file',
				      $self->{pattern});
			
			# force to flush
			$self->db_reload();
			
			my $entry_copied = Debconf::DbDriver->driver($dest_db_name)->cached($item->{'name'});
			
			# test copy result
			my $assert = $self->{assert};
			&$assert($item->{entry}, $entry_copied);

			Debconf::DbDriver->driver($src_db_name)->removeowner($item->{name}, $owner);
			Debconf::DbDriver->driver($dest_db_name)->removeowner($item->{name}, $owner);
		}
	}
}
	

sub copydb {
	my $self = shift;
	my $src_driver = shift;
	my $dest_driver = shift;
	my $name = shift;
	my $pattern = shift;
	my $owner_pattern = shift;
	
# Set up a copier to handle copying from one to the other.
#	my $src = Debconf::DbDriver->driver("configdb");
	my $copier = Debconf::DbDriver::Backup->new(
						    db => $src_driver, 
						    backupdb => $dest_driver, 
						    name => $name);

# Now just iterate over all items in src that patch the pattern, and tell
# the copier to make a copy of them.
	my $i=$copier->iterator;
	while (my $item=$i->iterate) {
		next unless $item =~ /$pattern/;
		
		if (defined $owner_pattern) {
			my $fit_owner = 0;
			my $owner;
			foreach $owner ($src_driver->owners($item)){
				$fit_owner = 1 if $owner =~ /$owner_pattern/;
			}
			next unless $fit_owner;
		}
		$copier->copy($item, $src_driver, $dest_driver);
	}
	
	$copier->shutdown;

}

sub db_reload {
	my $self = shift;

	# FIXME: we loop on all drivers because Debconf::Db->save shutdown only
	# drivers which are declared in Config and Templates in conf file
	# hope to be fixed soon
#	Debconf::Db->save;
	foreach my $driver_name (keys %Debconf::DbDriver::drivers) {
		Debconf::DbDriver->driver($driver_name)->shutdown;
	}
	Debconf::Db->load;
}

sub db_init {
	my $self = shift;
	chomp(my $pwd = `pwd`);

	# config temp file
	$self->{config_file} = new File::Temp( DIR => $self->{tmp_dir});
	$self->{config_filename} = $self->{config_file}->filename;

	# template temp file
	$self->{template_file} = new File::Temp( DIR => $self->{tmp_dir});
	$self->{template_filename} = $self->{template_file}->filename;

	# filedb temp file
	$self->{filedb_file} = new File::Temp( DIR => $self->{tmp_dir});
	$self->{filedb_filename} = $self->{filedb_file}->filename;

	# dirtreedb temp dir
	$self->{dirtreedb_dir} = File::Temp->tempdir('dirtreedb-XXXX', DIR => $self->{tmp_dir});

	# packdirdb temp dir
	$self->{packdirdb_dir} = File::Temp->tempdir('packdirdb-XXXX', DIR => $self->{tmp_dir});

	# passwddb temp file
	$self->{passwddb_file} = new File::Temp( DIR => $self->{tmp_dir});
	$self->{passwddb_filename} = $self->{passwddb_file}->filename;

	# build conf file
	$self->{conf_file} = new File::Temp( DIR => $self->{tmp_dir});
	$self->{conf_filename} = $self->{conf_file}->filename;
	open(OUTFILE, ">$self->{conf_filename}");
	print OUTFILE gettext(<<EOF);
Config: configdb
Templates: templatedb

Name: configdb
Driver: File
Mode: 644
Filename: $self->{config_filename}

Name: filedb
Driver: File
Mode: 644
Filename: $self->{filedb_filename}

Name: dirtreedb
Driver: DirTree
Directory: $self->{dirtreedb_dir}

Name: packdirdb
Driver: PackageDir
Directory: $self->{packdirdb_dir}

Name: ldapdb
Driver: LDAP
Server: localhost
Port: 9009
BaseDN: cn=debconf,dc=debian,dc=org
BindDN: cn=admin,dc=debian,dc=org
BindPasswd: debian

Name: passwddb
Driver: File
Filename: $self->{passwddb_filename}
Mode: 600
Accept-Type: password

Name: templatedb
Driver: File
Mode: 644
Filename: $self->{template_filename}

EOF

	close OUTFILE;
	
	# the only solution to test debconf-copydb with
	# different conf file => VERY UGLY
	@Debconf::Config::config_files =("$self->{conf_filename}");
	Debconf::Db->load;
}

sub set_up {
	my $self = shift;

#	system("mkdir -p $tmp_base_dir") == 0
#		or die "Can not create tmp data directory";

	$self->{tmp_dir} = $tmp_base_dir;
#	$self->{slapd} = Test::Debconf::DbDriver::SLAPD->new('localhost',9009,$self->{tmp_dir});
#	$self->{slapd}->slapd_start();
	$self->db_init();
}

sub tear_down {
	my $self = shift;

	Debconf::Db->save;
#	$self->{slapd}->slapd_stop();

#	system("rm -rf $self->{tmp_dir}") == 0
#		or die "Can not delete tmp data directory";
}

sub suite {
	my $self = shift;

	my $testsuite = Test::Unit::TestSuite->new(__PACKAGE__);
	my $wrapper = CopyDBTestSetup->new($testsuite);
    
	return $wrapper;
}
1;
