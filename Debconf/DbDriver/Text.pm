#!/usr/bin/perl -w

=head1 NAME

Debconf::Db::Text - plain text debconf db driver

=cut

package Debconf::DbDriver::Text;
use strict;
use Debconf::Log qw{:all};
use base qw(Debconf::DbDriver::FlatDir);

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

=head1 METHODS

=head2 load(itemname)

Load up entire item, and return a structure as required by
Debconf::DbDriver::Cached.

=cut

sub load {
	my $this=shift;
	my $item=shift;
	
	return unless $this->accept($item);
	debug "DbDriver $this->{name}" => "loading $item";
	my $file=$this->filename($item);
	return unless -e $file;
	
	my %ret=(
		owners => {},
		fields => {},
		variables => {},
		flags => {},
	);

	open(TEXTDB_IN, $file) or $this->error("$file: $!");
	my $invars=0;
	my $line;
	local $/="\n"; # make sure it's sane
	while ($line = <TEXTDB_IN>) {
		chomp $line;
		# Process variables.
		if ($invars) {
			if ($line =~ /^\s/) {
				$line =~ s/^\s+//;
				my ($var, $value)=split(/\s*=\s*/, $line, 2);
				$value=~s/\\n/\n/g;
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
			$value=~s/\\n/\n/g;
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
	return unless $this->accept($item);
	debug "DbDriver $this->{name}" => "saving $item";
	return if $this->{readonly};
	my %data=%{shift()};
	my $file=$this->filename($item);

	open(TEXTDB_OUT, ">$file") or $this->error("$file: $!");
	foreach my $field (sort keys %{$data{fields}}) {
		my $val=$data{fields}->{$field};
		$val=~s/\n/\\n/g;
		print TEXTDB_OUT ucfirst($field).": $val\n";
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
			my $val=$data{variables}->{$var};
			$val=~s/\n/\\n/g;
			print TEXTDB_OUT " $var = $val\n";
		}
	}
	print TEXTDB_OUT "\n";
	close TEXTDB_OUT;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
