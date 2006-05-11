#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Noninteractive::Error - noninteractive error message Element

=cut

package Debconf::Element::Noninteractive::Error;
use strict;
use Text::Wrap;
use Debconf::Gettext;
use Debconf::Config;
use Debconf::Log ':all';
use base qw(Debconf::Element::Noninteractive);

=head1 DESCRIPTION

This is a noninteractive error message Element. Since we are running
non-interactively, we can't pause to show the error messages. Instead, they
are mailed to someone.

=cut

=head1 METHODS

=over 4

=item show

Calls sendmail to mail the error, if the error has not been seen before.

=cut

sub show {
	my $this=shift;

	if ($this->question->flag('seen') ne 'true') {
		$this->sendmail(gettext("Debconf was not configured to display this error message, so it mailed it to you."));
	}
	$this->value('');
}

=item sendmail

The sendmail method mails the text to root. The external unix mail
program is used to do this, if it is present.

If the mail is successfully sent a true value is returned. Also, the
question is marked as seen.

A footer may be passed as the first parameter; it is generally used to
explain why the note was sent.

=cut

sub sendmail {
	my $this=shift;
	my $footer=shift;
	return unless length Debconf::Config->admin_email;
	if (-x '/usr/bin/mail') {
		debug user => "mailing a note";
	    	my $title=gettext("Debconf").": ".
			$this->frontend->title." -- ".
			$this->question->description;
		unless (open(MAIL, "|-")) { # child
			exec("mail", "-s", $title, Debconf::Config->admin_email) or return '';
		}
		# Let's not clobber this, other parts of debconf might use
		# Text::Wrap at other spacings.
		my $old_columns=$Text::Wrap::columns;
		$Text::Wrap::columns=75;
#		$Text::Wrap::break=q/\s+/;
		if ($this->question->extended_description ne '') {
			print MAIL wrap('', '', $this->question->extended_description);
		}
		else {
			# Evil note!
			print MAIL wrap('', '', $this->question->description);
		}
		print MAIL "\n\n";
		my $hostname=`hostname -f 2>/dev/null`;
		if (! defined $hostname) {
			$hostname="unknown system";
		}
		print MAIL "-- \n", sprintf(gettext("Debconf, running at %s"), $hostname, "\n");
		print MAIL "[ ", wrap('', '', $footer), " ]\n" if $footer;
		close MAIL or return '';

		$Text::Wrap::columns=$old_columns;
	
		# Mark this note as seen. The frontend doesn't do this for us,
		# since we are marked as not visible.
		$this->question->flag('seen', 'true');

		return 1;
	}
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>
Colin Watson <cjwatson@debian.org>

=cut

1
