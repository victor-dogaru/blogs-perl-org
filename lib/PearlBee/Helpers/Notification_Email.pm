package PearlBee::Helpers::Notification_Email;

use strict;
use warnings;

use Dancer2;
use Email::Template;

use Email::MIME;
use IO::All;
use MIME::Lite::TT;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;
use Data::Dumper;

use Try::Tiny;
use FindBin;
use Cwd qw( realpath );
use lib realpath("$FindBin::Bin/../lib");

sub announce_contributor {
    my ($self, $args) = @_;
    my $user     = $args->{user};
    my $invitee  = $args->{invitee};
    my $config   = $args->{config};

    try {
        PearlBee::Helpers::Email::send_email_complete({
            template => 'newBPO-user.tt',
            from     => $config->{'default_email_sender'},
            to       => $user->email,
            subject  => 'You have a new contributor on your blog',

            template_params => {
                config     => $config,
                name       => $user->name,
                username   => $user->username,
                email      => $user->email,
                added_user => $invitee->name
                #signature => config->{'email_signature'}
            }
        });
    }
    catch {
        error $_;
    };

}

sub invite_contributor {
    my ($self, $args) = @_;
    my $user     = $args->{user};
    my $invitee  = $args->{invitee};
    my $config   = $args->{config};
    my $blog     = $args->{blog};

    try {
        PearlBee::Helpers::Email::send_email_complete({
            template => 'existingBPO-user.tt',
            from     => $config->{'default_email_sender'},
            to       => $invitee->email,
            subject  => 'You have been invited to join a blog',

            template_params => {
                config     => $config,
                name       => $invitee->name,
                username   => $invitee->username,
                email      => $invitee->email,
                inviter    => $user->name,
                blog       => $blog
                #signature => config->{'email_signature'}
            }
        });
    }
    catch {
        error $_;
    };

}

1;
