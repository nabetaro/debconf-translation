#!/usr/bin/perl -w
#
# Each Element::Dialog::Input represents a item that the user needs to
# enter input into.

package Element::Dialog::Input;
use strict;
use Element::Input;
use ConfigDb;
use vars qw(@ISA);
@ISA=qw(Element::Input);

# Display the element, prompt the user for input.
sub show {
	my $this=shift;

	# Get the question that is bound to this element.
	my $question=ConfigDb::getquestion($this->{question});
	
	# How dialog is called depends on what type of question this is.
	my $type=$question->template->type;
	my $default=$question->value || $question->template->default;
	my @params=();
	if ($type eq 'boolean') {
		@params=('--yesno', $question->template->extended_description,
		         7, 0);
		if ($default eq 'false') {
			push @params, '--defaultno';
		}
	}
	elsif ($type eq 'select') {
		@params=('--menu', 
			 $question->template->extended_description,
			 16, 0, 8);
		my $c=0;			 
		foreach (@{$question->template->choices}) {
			push @params, $c++, $_;
		}
	}
	elsif ($type eq 'text') {
		# Wrap the text that goes in so I can figure out how many
		# lines it takes.
		@params=('--inputbox', $question->template->extended_description, 0 + 7, 
			 $question->template->extended_description, 16, 75, 
			 $default);
	}
	else {
		die "Unsupported data type \"$type\"";
	}

	my $value;
	my ($ret, $text)=$this->frontend->show_dialog(
		$question->template->description, @params);

	if ($type eq 'boolean') {
		$value=($ret eq 0 ? 'true' : 'false');
	}
	elsif ($type eq 'select') {
		my @choices=@{$question->template->choices};
		$value=$choices[$text];
	}
	elsif ($type eq 'text') {
		$value=$text;
	}

	$question->value($value);
}

1
