#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Editor - Edit a config file to answer questions

=cut

package Debconf::FrontEnd::Editor;
use strict;
use Debconf::Encoding q(wrap);
use Debconf::TmpFile;
use Debconf::Gettext;
use base qw(Debconf::FrontEnd::ScreenSize);

my $fh;

=head1 DESCRIPTION

This FrontEnd isn't really a frontend. It just generates a series of config
files and runs the users editor on them, then parses the result.

=head1 METHODS

=over 4

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);
	$this->interactive(1);
}

=item comment

Displays a comment, word-wrapped.

=cut

sub comment {
	my $this=shift;
	my $comment=shift;

#	$Text::Wrap::break=q/\s+/;
	print $fh wrap('# ','# ',$comment);
	$this->filecontents(1);
}

=item separator

Displays a divider bar; a line of hashes.

=cut

sub divider {
	my $this=shift;

	print $fh ("\n".('#' x ($this->screenwidth - 1))."\n");
}

=item item

Displays an item. First parameter is the item's name, second is its value.

=cut

sub item {
	my $this=shift;
	my $name=shift;
	my $value=shift;

	print $fh "$name=\"$value\"\n\n";
	$this->filecontents(1);
}

=item go

Items write out data into a temporary file, which is then edited with the
user's editor. Then the file is parsed back in.

=cut

sub go {
	my $this=shift;
	my @elements=@{$this->elements};
	return 1 unless @elements;
	
	# End the filename in .sh because it is basically a shell
	# format file, and this makes some editors do good things.
	$fh = Debconf::TmpFile::open('.sh');

	$this->comment(gettext("You are using the editor-based debconf frontend to configure your system. See the end of this document for detailed instructions."));
	$this->divider;
	print $fh ("\n");

	$this->filecontents('');
	foreach my $element (@elements) {
		$element->show;
	}

	# Only proceed if something interesting was actually written to the
	# file.
	if (! $this->filecontents) {
		Debconf::TmpFile::cleanup();
		return 1;
	}
	
	$this->divider;
	$this->comment(gettext("The editor-based debconf frontend presents you with one or more text files to edit. This is one such text file. If you are familiar with standard unix configuration files, this file will look familiar to you -- it contains comments interspersed with configuration items. Edit the file, changing any items as necessary, and then save it and exit. At that point, debconf will read the edited file, and use the values you entered to configure the system."));
	print $fh ("\n");
	close $fh;
	
	# Launch editor.
	my $editor=$ENV{EDITOR} || $ENV{VISUAL} || '/usr/bin/editor';
	# $editor may possibly contain spaces and options
	system "$editor ".Debconf::TmpFile->filename;

	# Now parse the temporary file, looking for lines that look like
	# items. Figure out which Element corresponds to the item, and
	# pass the text into it to be processed.
	# FIXME: this isn't really very robust. Syntax errors are ignored.
	my %eltname=map { $_->question->name => $_ } @elements;
	open (IN, "<".Debconf::TmpFile::filename());
	while (<IN>) {
		next if /^\s*#/;

		if (/(.*?)="(.*)"/ && $eltname{$1}) {
			# Elements can override the value method to
			# process the input.
			$eltname{$1}->value($2);
		}
	}
	close IN;
	
	Debconf::TmpFile::cleanup();

	return 1;
}

=item screenwidth

This method from my base class is overridden, so after the screen width
changes, $Debconf::Encoding::columns is updated to match.

=cut

sub screenwidth {
	my $this=shift;

	$Debconf::Encoding::columns=$this->SUPER::screenwidth(@_);
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
