package PearlBee::Routes::Notification;

=head1 PearlBee::Routes::Notification

Notification routes

=cut

use Dancer2 0.163000;
use Dancer2::Plugin::DBIC;
use PearlBee::Helpers::Util qw(map_posts);
use PearlBee::Helpers::Pagination qw(get_total_pages get_previous_next_link);
use PearlBee::Dancer2::Plugin::Admin;

our $VERSION = '0.1';

=head2 /notification

View all notifications

=cut

get '/notification' => sub {

  my $res_user = resultset('Users')->find_by_session(session);
  if (!$res_user){
    redirect "/";
  }
  my $counter  = resultset('Notification')->search({
  user_id      => $res_user->id,
  name         =>  'changed role'
  })->count;
   $counter   += resultset('Notification')->search({
  user_id      => $res_user->id,
  name         =>  'comment',
  viewed       => 0
  })->count;

  $counter    += resultset('Notification')->search({
  user_id      => $res_user->id,
  name         =>  'invitation',
  viewed       => 0
  })->count;
  $counter     += resultset('Notification')->search({
  sender_id    => $res_user->id,
  name         => 'response'
  })->count;
  template 'admin/notification/notification',
    {
      counter => $counter
    }, { layout  => 'admin' };

};


=head2 /notification/comment/:id/user/:username/mark-read

View all notifications

=cut

get '/notification/comment/:id/user/:username/mark-read/:status' => sub {

  my $res_user        = resultset('Users')->find_by_session(session);
  my $id              = route_parameters->{'id'};
  my $username        = route_parameters->{'username'};
  my $invitation_user = resultset('Users')->find({ username => $username });
  my $user_id         = $invitation_user->id;
  my $status          = route_parameters->{'status'};

  resultset('Notification')->read_comment({
    comment_id => $id,
    user_id    => $user_id,
    status     => $status
  });

  redirect '/notification'
};


=head2 /notification/invitation/blog/:blogname/mark-read/:status

View all notifications

=cut

get '/notification/invitation/blog/:blogname/mark-read/:status' => sub {

  my $res_user        = resultset('Users')->find_by_session(session);
  my $blog_name       = route_parameters->{'blogname'};
  my $blog            = resultset('Blog')->find ({ name => $blog_name });
  my $status          = route_parameters->{'status'};

  my $notification    = resultset('Notification')->read_invitation({
    blog_id => $blog->id,
    user_id => $res_user->id,
    status  => $status
  });

  my $role_flag;
  
  if ($notification->role eq 'admin'){
    $role_flag = 1;
  }
  else {
    $role_flag = 0;
  }

  if  ($status eq 'true'){
    my $new_entry = resultset('BlogOwner')->create({
     blog_id  => $blog->id,
     user_id  => $res_user->id,
     is_admin =>  $role_flag,
     status         => 'active',
     activation_key => '',
     });
  }
  my $invitation = resultset('Notification')->find({
    generic_id => $blog->id,
    user_id => $res_user->id,
    });
  my $new_notification = resultset('Notification')->create ({
      name => 'response',
      user_id => $res_user->id,
      sender_id => $invitation->sender_id,
      created_date =>DateTime->now(),
      accepted => $status eq 'true'? 1 : 0,
      generic_id => $blog->id,
    });
  redirect '/notification'
};

=head2 /notification/response/:id/user/:username/mark-read

View all notifications

=cut

get '/notification/response/:id/user/:username/mark-read/:status' => sub {

  my $res_user        = resultset('Users')->find_by_session(session);
  my $username        = route_parameters->{'username'};
  my $id              = route_parameters->{'id'};
  my $invitation_user = resultset('Users')->find({ username => $username });
  my $user_id         = $invitation_user->id;
  my $status          = route_parameters->{'status'};

  resultset('Notification')->read_response({
    blog_id => $id,
    user_id => $user_id,
    status  => $status
  });

  redirect '/notification'
};


=head2 /notification/changed_role/:id/user/:username/mark-read

View all notifications

=cut

get '/notification/changed_role/:id/user/:username/mark-read/:status' => sub {

  my $res_user        = resultset('Users')->find_by_session(session);
  my $username        = route_parameters->{'username'};
  my $id              = route_parameters->{'id'};
  my $invitation_user = resultset('Users')->find({ username => $username });
  my $user_id         = $invitation_user->id;
  my $status          = route_parameters->{'status'};

  resultset('Notification')->read_changed_role({
    blog_id => $id,
    user_id => $user_id,
    status  => $status,
  });

  redirect '/notification'
};


1;
