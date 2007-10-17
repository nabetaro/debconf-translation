#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Readline - Terminal frontend with readline support

=cut

package Debconf::FrontEnd::Readline;
use strict;
use Term::ReadLine;
use Debconf::Gettext;
use base qw(Debconf::FrontEnd::Teletype);

=head1 DESCRIPTION

This FrontEnd is for a traditional unix command-line like user interface.
It features completion if you're using Gnu readline.

=head1 FIELDS

=over 4

=item readline

An object of type Term::ReadLine, that is used to do the actual prompting.

=item promptdefault

Set if the varient of readline being used is so lame that it cannot display
defaults, so the default must be part of the prompt instead.

=back

=head1 METHODS

=over 4

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);

	# Yeah, you need a controlling tty. Make sure there is one.
	open(TESTTY, "/dev/tty") || die gettext("This frontend requires a controlling tty.")."\n";
	close TESTTY;

	$Term::ReadLine::termcap_nowarn = 1; # Turn off stupid termcap warning.
	$this->readline(Term::ReadLine->new('debconf'));
	$this->readline->ornaments(1);

	if (Term::ReadLine->ReadLine =~ /::Gnu$/) {
		# Well, emacs shell buffer has some annoying interactions
		# with Term::ReadLine::GNU. It's not worth the pain.
		if (exists $ENV{TERM} && $ENV{TERM} =~ /emacs/i) {
			die gettext("Term::ReadLine::GNU is incompatable with emacs shell buffers.")."\n";
		}
		
		# Ctrl-u or pageup backs up, while ctrl-v or pagedown moves
		# forward. These key bindings and history completion are only
		# supported by Gnu ReadLine.
		$this->readline->add_defun('previous-question',	
			sub {
				if ($this->capb_backup) {
					$this->_skip(1);
					$this->_direction(-1);
					# Tell readline to quit. Yes, 
					# this is really the best way. <sigh>
					$this->readline->stuff_char(ord "\n");
				}
				else {
					$this->readline->ding;
				}
			}, ord "\cu");
		# This is only defined so people have a readline function
		# they can remap if they desire.
		$this->readline->add_defun('next-question',
			sub {
				if ($this->capb_backup) {
					# Just move onward.
					$this->readline->stuff_char(ord "\n");
				}
			}, ord "\cv");
		# FIXME: I cannot figure out a better way to feed in a key 
		# sequence -- someone help me.
		$this->readline->parse_and_bind('"\e[5~": previous-question');
		$this->readline->parse_and_bind('"\e[6~": next-question');
		$this->capb('backup');
	}
	
	# Figure out which readline module has been loaded, to tell if
	# prompts must include defaults or not.
	if (Term::ReadLine->ReadLine =~ /::Stub$/) {
		$this->promptdefault(1);
	}
}

=item elementtype

This frontend uses the same elements as does the Teletype frontend.

=cut

sub elementtype {
	return 'Teletype';
}

=item go

Overrides the default go method with something a little more sophisticated.
This frontend supports backing up, but it doesn't support displaying blocks of
questions at the same time. So backing up from one block to the next is
taken care of for us, but we have to handle movement within a block. This
includes letting the user move back and forth from one question to the next
in the block, which this method supports.

The really gritty part is that it keeps track of whether the user moves all
the way out of the current block and back, in which case they have to start
at the _last_ question of the previous block, not the first.

=cut

sub go {
	my $this=shift;

	# First, take care of any noninteractive elements in the block.
	foreach my $element (grep ! $_->visible, @{$this->elements}) {
		my $value=$element->show;
		return if $this->backup && $this->capb_backup;
		$element->question->value($value);
	}

	# Now we only have to deal with the interactive elements.
	my @elements=grep $_->visible, @{$this->elements};
	unless (@elements) {
		$this->_didbackup('');
		return 1;
	}

	# Figure out where to start, based on if we backed up to get here.
	my $current=$this->_didbackup ? $#elements : 0;

	# Loop through the elements from starting point until we move
	# out of either side. The property named "_direction" will indicate
	# which direction to go next; it is changed elsewhere.
	$this->_direction(1);
	for (; $current > -1 && $current < @elements; $current += $this->_direction) {
		my $value=$elements[$current]->show;
	}

	if ($current < 0) {
		$this->_didbackup(1);
		return;
	}
	else {
		$this->_didbackup('');
		return 1;
	}
}

=item prompt

Prompts the user for input, and returns it. If a title is pending,
it will be displayed before the prompt.

This function will return undef if the user opts to skip the question 
(by backing up or moving on to the next question). Anything that uses this
function should catch that and handle it, probably by exiting any
read/validate loop it is in.

The function uses named parameters.

Completion amoung available choices is supported. For this to work, if
a reference to an array of all possible completions is passed in.

=cut

sub prompt {
	my $this=shift;
	my %params=@_;
	my $prompt=$params{prompt}." ";
	my $default=$params{default};
	my $noshowdefault=$params{noshowdefault};
	my $completions=$params{completions};

	if ($completions) {
		# Set up completion function (a closure).
		my @matches;
		$this->readline->Attribs->{completion_entry_function} = sub {
			my $text=shift;
			my $state=shift;
			
			if ($state == 0) {
				@matches=();
				foreach (@{$completions}) {
					push @matches, $_ if /^\Q$text\E/i;
				}
			}

			return pop @matches;
		};
	}
	else {
		$this->readline->Attribs->{completion_entry_function} = undef;
	}

	if (exists $params{completion_append_character}) {
		$this->readline->Attribs->{completion_append_character}=$params{completion_append_character};
	}
	else {
		$this->readline->Attribs->{completion_append_character}='';
	}
	
	$this->linecount(0);
	my $ret;
	$this->_skip(0);
	if (! $noshowdefault) {
		$ret=$this->readline->readline($prompt, $default);
	}
	else {
		$ret=$this->readline->readline($prompt);
	}
	$this->display_nowrap("\n");
	return if $this->_skip;
	$this->_direction(1);
	$this->readline->addhistory($ret);
	return $ret;
}

=item prompt_password

Safely prompts for a password; arguments are the same as for prompt.

=cut

sub prompt_password {
	my $this=shift;
	my %params=@_;

	if (Term::ReadLine->ReadLine =~ /::Perl$/) {
		# I hate this library. Sigh. It always echos,
		# so it is unusable here. Use Teletype's prompt_password.
		return $this->SUPER::prompt_password(%params);
	}
	
	# Kill default: not a good idea for passwords.
	delete $params{default};
	# Force echoing off.
	system('stty -echo 2>/dev/null');
	my $ret=$this->prompt(@_, noshowdefault => 1, completions => []);
	system('stty sane 2>/dev/null');
	print "\n";
	return $ret;
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
