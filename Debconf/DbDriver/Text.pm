#!/usr/bin/perl -w

=head1 NAME

Debconf::Db::Text - plain text debconf db driver

=cut

package Debconf::DbDriver::Text;
use strict;
use base qw(Debconf::DbDriver::Cache Debconf::DbDriver::FlatDir);

=head1 DESCRIPTION

This is a debconf database driver that uses a plain text file for each
individual item. The file format is rfc-822-ishl; similar to a Debian
control file. An example:

  Template: foo/template
  Value: foobar
  Owners: foo, bar
  Flags: seen, blert, meep
  Variables:
   var1 = val1
   var2 = another value
   var3 = yet another value

All listed flags are set; unset flags will not be listed.

=head1 FIELDS

=head2 load(itemname)

Load up entire item, and return a structure as required by
Debconf::DbDriver::Cached.

=cut

sub load {
	my $this=shift;
	my $item=shift;
	my $file=$this->filename($item);
	return unless -e $file;
	
	my %ret=(
		owners => {},
		fields => {},
		variables => {},
		flags => {},
	);

	open(TEXTDB_IN, $file) or die "$file: $!";
	my $invars=0;
	my $line;
	while ($line = <TEXTDB_IN>) {
		chomp $line;

		# Process variables.
		if ($invars) {
			if ($line =~ /^\s/) {
				$line =~ s/^\s+//;
				my ($var, $value)=split(/\s*=\s*/, $line, 2);
				$ret{variables}->{$var}=$value;
				next;
			}
			else {
				$invars=0;
			}
		}

		# Process the main structure.
		my ($key, $value)=split(/:\s*/, $line, 2);
		$key=lc($key);
		if ($key eq 'owners') {
			foreach my $owner (split(/,\s+/, $value)) {
				$ret{owners}->{$owner}=1;
			}
		}
		elsif ($key eq 'flags') {
			foreach my $flag (split(/,\s+/, $value)) {
				$ret{flags}->{$flag}='true';
			}
		}
		elsif ($key eq 'variables') {
			$invars=1;	
		}
		elsif (length $key) {
			$ret{fields}->{$key}=$value;
		}
	}
	close TEXTDB_IN;

	return \%ret;
}

=head2 save(itemname,value)

Writes out the file.

=cut

sub save {
	my $this=shift;
	my $item=shift;
	my %data=%{shift()};
	my $file=$this->filename($item);

	return if $this->readonly;

	open(TEXTDB_OUT, ">$file") or die "$file: $!";
	foreach my $field (sort keys %{$data{fields}}) {
		print TEXTDB_OUT ucfirst($field).": ".$data{fields}->{$field}."\n";
	}
	if (keys %{$data{owners}}) {
		print TEXTDB_OUT "Owners: ".join(", ", keys(%{$data{owners}}))."\n";
	}
	if (keys %{$data{flags}}) {
		print TEXTDB_OUT "Flags: ".join(", ",
			grep { $data{flags}->{$_} eq 'true' }
				sort keys(%{$data{flags}}))."\n";
	}
	if (keys %{$data{variables}}) {
		print TEXTDB_OUT "Variables:\n";
		foreach my $var (sort keys %{$data{variables}}) {
			print TEXTDB_OUT " $var = ".$data{variables}->{$var}."\n";
		}
	}
	print TEXTDB_OUT "\n";
	close TEXTDB_OUT;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
