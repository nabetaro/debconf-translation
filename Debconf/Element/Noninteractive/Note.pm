#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Noninteractive::Note - noninteractive note Element

=cut

package Debconf::Element::Noninteractive::Note;
use strict;
use Text::Wrap;
use Debconf::Gettext;
use Debconf::Element::Noninteractive; # perlbug
use base qw(Debconf::Element::Noninteractive);

=head1 DESCRIPTION

This is a noninteractive note Element. Notes are generally some important peice
of information that you want the user to see sometime. Since we are running
non-interactively, we can't pause to show them. Instead, they are saved to
root's mailbox.

=cut

=head1 METHODS

=over 4

=item show

Calls sendmail to mail the note to root.

=cut

sub show {
	my $this=shift;

	$this->sendmail(gettext("Debconf was not configured to display this note, so it mailed it to you."));
	return '';
}

=item sendmail

The sendmail method mails the note to root if the note has not been displayed
before. The external unix mail program is used to do this, if it is present.

If the mail is successfully sent a true value is returned.

A footer may be passed as the first parameter; it is generally used to
explain why the note was sent.

=cut

sub sendmail {
	my $this=shift;
	my $footer=shift;

	if (-x '/usr/bin/mail' && $this->question->flag_isdefault ne 'false') {
	    	my $title=gettext("Debconf").": ".$this->frontend->title." -- ".
		   $this->question->description;
		$title=~s/'/\'/g;
	    	open (MAIL, "|mail -s '$title' root") or return '';
		# Let's not clobber this, other parts of debconf might use
		# Text::Wrap at other spacings.
		my $old_columns=$Text::Wrap::columns;
		$Text::Wrap::columns=75;
		if ($this->question->extended_description ne '') {
			print MAIL wrap('', '', $this->question->extended_description);
		}
		else {
			# Evil note!
			print MAIL wrap('', '', $this->question->description);
		}
		print MAIL "\n\n";
		print MAIL "-- \n", sprintf(gettext("Debconf, running at %s"), `hostname -f`);
		print MAIL "[ ", wrap('', '', $footer), " ]\n" if $footer;
		close MAIL or return '';

		$Text::Wrap::columns=$old_columns;
	
		# Mark this note as shown. The frontend doesn't do this for us,
		# since we are marked as not visible.
		$this->question->flag_isdefault('false');

		return 1;
	}
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
