#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::ConfigDb -- debian configuration database

=cut

=head1 DESCRIPTION

Debian configuration database. This is an interface to the actual
backend databases. It keeps track of Questions, Mappings, and Templates.
This is a simple perl module, not a full-fledged object. It's a bit of a
catchall, and perhaps the ugliest part of debconf.

It will probably need to be rewritten when we actually get a backend db.

=cut

=head1 METHODS

=cut

package Debian::DebConf::ConfigDb;
use Debian::DebConf::Template;
use Debian::DebConf::Question;
use Debian::DebConf::Mapping;
use strict;
use vars qw($AUTOLOAD %templates %questions %mappings);

=head2 getquestion

Pass in the name of the question and this will return the specified question
object.

=cut

sub getquestion {
	return $questions{(shift)};
}

=head2 loadtemplatefile

Loads up a file containing templates (pass the filename to load). Creates
Template objects and corresponding Mapping objects. The second parameter is
the name of the owner of the created templates and mappings.

=cut

sub loadtemplatefile {
	my $fn=shift;
	my $owner=shift;
	
	my $collect;
	open (TEMPLATE_IN, $fn) || die "$fn: $!";
	while (<TEMPLATE_IN>) {
		if ($_ ne "\n") {
			$collect.=$_;
		}
		if ($_ eq "\n" || eof TEMPLATE_IN) {
			# Have to be careful here to ensure that if a template
			# already exists in the db and we load it up, the
			# changes replace the old template without
			# instantiating a new template.
			my $template=Debian::DebConf::Template->new();
			$template->parse($collect);
			
			if ($templates{$template->template}) {
				# An old template with this name exists. Merge
				# all info from the new template into it.
				$template->merge($templates{$template->template});
			}
			else {
				$templates{$template->template}=$template;
			}

			$templates{$template->template}->addowner($owner);

			# If a mapping by this name exists, just use it.
			# Else make a new one.
			my $mapping=$mappings{$template->template};
			if (! $mapping) {
				$mapping=Debian::DebConf::Mapping->new();
			}
			$mapping->question($template->template);
			$mapping->template($template->template);
			$mapping->addowner($owner);
			$mappings{$template->template}=$mapping;
			
			$collect='';
		}
	}
	close TEMPLATE_IN;
	return 1;
}

=head2 makequestions

Instantiates Questions from Templates and Mappings.

=cut

sub makequestions {
	foreach my $mapping (values %mappings) {
		my $template=$templates{$mapping->template};
		
		# Is this question already instantiated?
		next if exists $questions{$mapping->question};

		my $question=Debian::DebConf::Question->new;
		$question->name($mapping->question);
		$question->template($template);
		$question->value($template->default);
		$questions{$question->name}=$question;
	}
}

=head2 addmapping

Create a Mapping and add it to the database. Pass the name of the template and
the name of the question it is mapped to, and also the name of the owner of
the new mapping.

=cut

sub addmapping {
	my $template_text=shift;
	my $location=shift;
	my $owner=shift;

	my $template=$templates{$template_text};

	# One might think that I need to make the template this new mapping
	# points to be owned by $owner, so the template doesn't accidentually
	# go away any time soon while it's still being used. However, doing
	# that causes a different problem: If this mapping is removed later,
	# how will we know if the template should remained owned by $owner
	# or not? After all, other mappings may still use it, or they may not.
	# So instead, I added some code to removetemplate() to handle
	# these cases, and I do not set the ownership of the template here.

	# Instantiate or change the mapping to point to the right question.
	my $mapping;
	if (exists $mappings{$location}) {
		$mapping=$mappings{$location};
		$mapping->addowner($owner);
		# Short circuit; no question change necessary.
		return if $mapping->template eq $template_text;
	}
	else {
		$mapping=Debian::DebConf::Mapping->new();
		$mapping->addowner($owner);
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
	$question->name($location);
	$question->template($template);
	$question->value($template->default);
	$questions{$question->name}=$question;
	$questions{$location}=$question;
}

=head2 removemapping

Give up ownership of a given mapping. Pass the name of the mapping and the
owner that is giving it up. When the number of owners reaches 0, the mapping
itself is removed as is the question associated with it.

=cut

sub removemapping {
	my $location=shift;
	my $owner=shift;
	
	$mappings{$location}->removeowner($owner);
	if ($mappings{$location}->owners eq '') {
		delete $mappings{$location};
		delete $questions{$location}
	}
}

=head2 removetemplate

Give up ownership of a given template. Pass the name of the template and the
owner that is giving it up. When the number of owners reaches 0, the template
itself is removed as are any mappings that use it, and any questions that use
them.

=cut

sub removetemplate {
	my $location=shift;
	my $owner=shift;
	
	$templates{$location}->removeowner($owner);
	if ($templates{$location}->owners eq '') {
		foreach my $maploc (keys %mappings) {
			if ($mappings{$maploc}->template eq $location) {
				removemapping($maploc, $owner);
			}
		}
		delete $templates{$location};
	}
}

=head2 savedb

Save the current state to disk. This is a quick hack, there is a whole
backend db in the spec that this ignores. Pass the filename to save to.

=cut

use Data::Dumper;
sub savedb {
	my $fn=shift;

	my $dumper=Data::Dumper->new([\%mappings, \%templates, \%questions],
		[qw{*mappings *templates *questions}]);
	$dumper->Indent(1);
	open (OUT, ">$fn") || die "$fn: $!";
	print OUT $dumper->Dump;
	print OUT "\n1;\n"; # Return a true value.
	close OUT;
}

=head2 loaddb

Loads the current state from disk. Again, a quick hack. Pass the filename
to load.

=cut

sub loaddb {
	require shift;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
