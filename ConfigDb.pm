#!/usr/bin/perl -w
#
# Debian configuration database. This includes questions and templates and
# is an interface to the actual backend databases.

package ConfigDb;
use Template;
use Question;
use strict;
use vars qw($AUTOLOAD %templates %questions);

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
			my $template=Template->new();
			$template->parse($collect);
			$templates{$template->template}=$template;
			
			$collect='';
		}
	}
	close TEMPLATE_IN;
	return 1;
}

# Instantiate Questions from templates and question mapping data.
sub makequestions {
	# TODO: currently, since I don't know what we're going to do for
	# mapping, I just instantiate one question per template.
	foreach my $template (values %templates) {
		my $question=Question->new;
		$question->name($template->template);
		$question->template($template);
		$question->value($template->default);
		$questions{$question->name}=$question;
	}
}

1
