#!/usr/bin/perl -w
#
# Pass this program a list of .pm files. It parses them (halfheartedly,
# it works on my code, may not on your code), and generates an inheritcance
# graph of the modules.

use strict;

my %kids;
my %iskid;

foreach my $file (@ARGV) {
	my $package='';
	my @isa=();
	open (IN,$file) || die "$file: $!";
	while (<IN>) {
		if (/package\s(\w+.*?);/) {
			$package=$1;
		}
		# Gag. This just looks for @ISA= lines.
		if (/\@ISA\s*=\s*(?:q(?:w|q)?(?:\(|{)|"|')(.*?)(?:}|\)|'|")/) {
			push @isa, split(/\s+/, $1);
		}
	}
	close IN;
	
	if ($package) {
		foreach (@isa) {
			$kids{$_}{$package}=1;
			$iskid{$package}=1;
		}
	}
}

my %seen;

# Recursively print out tree structure.
sub printkids {
	my $parent=shift;
	my $spacer=shift;
	
	foreach my $kid (sort keys %{$kids{$parent}}) {
		next if $seen{$kid};
		$seen{$kid}=1;
		# Strip off text in name that comes from any common parents.
		$_=$kid;
		foreach my $p (split(/::/,$parent)) {
			s/^$p\:://;
			
		}	
		print "$spacer$_\n";
		printkids($kid, "  $spacer");
	}
}

# Print all parents with thier kids under them.
# It's important to only print toplevel parents, which is why
# %iskid comes into play.
foreach my $parent (sort keys %kids) {
	next if $iskid{$parent};	
	print "$parent\n";
	printkids($parent, "  ");
}
