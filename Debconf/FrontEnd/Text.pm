#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Text - Text FrontEnd

=cut

package Debconf::FrontEnd::Text;
use strict;
use Text::Wrap;
use Term::ReadLine;
use Debconf::Gettext;
use Debconf::Config;
use base qw(Debconf::FrontEnd::Tty);

local $|=1;

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

	$Term::ReadLine::termcap_nowarn = 1; # Turn off stupid termcap warning.
	$this->readline(Term::ReadLine->new('debconf'));
	$this->readline->ornaments(1);

	if (Term::ReadLine->ReadLine =~ /::Gnu$/) {
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
	
	$this->interactive(1);
	$this->linecount(0);
	
	# Figure out which readline module has been loaded, to tell if
	# prompts must include defaults or not.
	if (Term::ReadLine->ReadLine =~ /::Stub$/) {
		$this->promptdefault(1);
	}
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

=item screenwidth

This method from my base class is overridden, so after the screen width
changes, $Text::Wrap::columns is updated to match.

=cut

sub screenwidth {
	my $this=shift;
	
	$Text::Wrap::columns=$this->SUPER::screenwidth(@_);
}

=item display

Displays text wrapped to fit on the screen. If too much text is displayed at
once, it will page it. If a title has been set and has not yet been displayed,
displays it first.

The important flag, if set, will make it always be shown. If unset, the
text will not be shown in terse mode,

=cut

sub display {
	my $this=shift;
	my $text=shift;
	
	$this->display_nowrap(wrap('','',$text));
}

=item display_nowrap

Display text, paging if necessary. If a title has been set and has not yet been
displayed, displays it first.

=cut

sub display_nowrap {
	my $this=shift;
	my $text=shift;

	# Terse mode skips all this stuff.
	return if Debconf::Config->terse eq 'true';

	# Silly split elides trailing null matches.
	my @lines=split(/\n/, $text);
	push @lines, "" if $text=~/\n$/;
	
	# Add to the display any pending title.
	my $title=$this->title;
	if (length $title) {
		unshift @lines, $title, ('-' x length $title), '';
		$this->title('');
	}

	foreach (@lines) {
		if ($this->linecount($this->linecount+1) > $this->screenheight - 2) {
			$this->prompt(
				prompt => '['.gettext("More").']',
				default => '',
				completions => [],
			);
		}
		print "$_\n";
	}
}

=item prompt

Prompts the user for input, and returns it. If a title is pending,
it will be displayed before the prompt.

This function will return undef if the user opts to skip the question 
(by backing up or moving on to the next question). Anything that uses this
function should catch that and handle it, probably by exiting any
read/validate loop it is in.

The function uses named paramerters.

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
	$this->_skip('');
	if (! $noshowdefault && $this->promptdefault && $default ne '') {
		$ret=$this->readline->readline($prompt."[$default] ", $default);
	}
	elsif (! $noshowdefault) {
		$ret=$this->readline->readline($prompt, $default);
	}
	else {
		$ret=$this->readline->readline($prompt);
	}
	$this->display_nowrap("\n");
	return if $this->_skip;
	$this->_direction(1);
	$this->readline->addhistory($ret);
	if ($ret eq '' && $this->promptdefault) {
		return $default;
	}
	return $ret;
}

=item prompt_password

Safely prompts for a password; arguments are the same as for prompt.

=cut

sub prompt_password {
	my $this=shift;
	my %params=@_;

	# Force echoing off.
	system('stty -echo');
	my $ret;
	if (Term::ReadLine->ReadLine =~ /::Perl$/) {
		# I hate this library. Sigh. It always echos,
		# so it is unusable here.
		local $|=1;
		print $params{prompt}." ";	
		$ret=<STDIN>;
		chomp $ret;
		# Their newline won't have registered, so simulate it.
		print "\n";
	}
	else {
		$ret=$this->prompt(@_, noshowdefault => 1, completions => []);
	}
	system('stty sane');
	print "\n";
	return $ret;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
