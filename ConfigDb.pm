#!/usr/bin/perl -w
#
# Debian configuration database. This includes questions and templates and
# is an interface to the actual backend databases.

package Debian::DebConf::ConfigDb;
use Debian::DebConf::Template;
use Debian::DebConf::Question;
use Debian::DebConf::Mapping;
use strict;
use vars qw($AUTOLOAD %templates %questions %mappings);

# Pass in the name of the question and this will return the specified question
# object.
sub getquestion {
	return $questions{(shift)};
}

# Loads up a file containing templates.
sub loadtemplatefile {
	my $fn=shift;
	
	die "No filename to load specified" unless $fn;
	
	my $collect;
	open (TEMPLATE_IN, $fn) || die "$fn: $!";
	while (<TEMPLATE_IN>) {
		if ($_ ne "\n") {
			$collect.=$_;
		}
		if ($_ eq "\n" || eof TEMPLATE_IN) {
			my $template=Debian::DebConf::Template->new();
			$template->parse($collect);
			$templates{$template->template}=$template;
			
			$collect='';
		}
	}
	close TEMPLATE_IN;
	return 1;
}

# Loads up a file containing mappings.
sub loadmappingfile {
	my $fn=shift;
	
	die "No filename to load specified" unless $fn;
	my $collect;
	open (MAPPING_IN, $fn) || die "$fn: $!";
	while (<MAPPING_IN>) {
		if ($_ ne "\n") {
			$collect.=$_;
		}
		if ($_ eq "\n" || eof MAPPING_IN) {
			my $mapping=Debian::DebConf::Mapping->new();
			$mapping->parse($collect);
			$mappings{$mapping->question}=$mapping;
			$collect='';
		}	
	}
	close MAPPING_IN;
	return 1;
}

# Instantiate Questions from templates and question mapping data.
sub makequestions {
	foreach my $mapping (values %mappings) {
		# Is this question already instantiated?
		my $template=$templates{$mapping->template};
		
		# Is this question already instantiated?
		next if exists $questions{$template->template};

		my $question=Debian::DebConf::Question->new;
		$question->name($template->template);
		$question->template($template);
		$question->value($template->default);
		$questions{$question->name}=$question;
	}
}

# Add a mapping.
sub addmapping {
	my $template_text=shift;
	my $location=shift;

	my $template=$templates{$template_text};

	# Instantiate or change the mapping to point to the right question.
	my $mapping;
	if (exists $mappings{$location}) {
		$mapping=$mappings{$location};
		# Short circuit; no change necessary.
		return if $mapping->template eq $template_text;
	}
	else {
		$mapping=Debian::DebConf::Mapping->new();
	}
	$mapping->question($location);
	$mapping->template($template_text);
	$mappings{$location}=$mapping;
	
	# Instantiate or change the question.
	my $question;
	if (exists $questions{$location}) {
		$question=$questions{$location};
	}
	else {
		$question=Debian::DebConf::Question->new;
	}
	$question->name($template->template);
	$question->template($template);
	$question->value($template->default);
	$questions{$question->name}=$question;
	$questions{$location}=$question;
}

# Remove a mapping.
sub removemapping {
	my $location=shift;
	
	delete $mappings{$location};
}

# Save the current state to disk. This is a quick hack, there is a whole
# backend db in the spec that this ignores.
use Data::Dumper;
sub savedb {
	my $fn=shift;

	$Data::Dumper::Indent=1;
	open (OUT, ">$fn") || die "$fn: $!";
	print OUT Data::Dumper->Dump([\%mappings], [qw{*mappings}]);
	# This saves the templates too.
	print OUT Data::Dumper->Dump([\%questions], [qw{*questions}]);
	close OUT;
}

# Load the current state from disk. Again, a quick hack.
sub loaddb {
	require shift;
}

1
