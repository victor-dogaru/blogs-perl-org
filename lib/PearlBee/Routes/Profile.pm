package PearlBee::Routes::Profile;

=head1 PearlBee::Routes::Profile

Profile routes from the old PearlBee main file

=cut

use Encode qw( decode_utf8 );
use Dancer2 0.163000;
use Dancer2::Plugin::DBIC;

use PearlBee::Helpers::Access qw( has_ability );
use PearlBee::Helpers::ProcessImage;
use Try::Tiny;
use PearlBee::Dancer2::Plugin::Admin;
our $VERSION = '0.1';

=head2 hook 'before'

=cut

hook before => sub {
  my $user = session('user');
  my $user_obj = resultset('Users')->find_by_session(session);

  if ( request->dispatch_path =~ m{ ^/profile/author }x ) {
    # Do nothing, /profile/author can be viewed by anyone.
  }
  elsif ( request->dispatch_path =~ m{ ^/profile }x ) {
    if ( $user ) {
      if ( !PearlBee::Helpers::Access::has_ability( $user, 'update profile' ) ) {
        forward '/', { requested_path => request->dispatch_path };
      }
    }
  }
};

=head2 /profile route

Display profile page

=cut

get '/profile' => sub {

  my $user_obj = resultset('Users')->find_by_session(session);
  if (!$user_obj){
    redirect ('/');
  }
  template 'profile';

};

=head2 /profile/author/:username route

Display profile for a given author

=cut

get '/profile/author/:username' => sub {

  my $nr_of_rows = config->{blogs_on_page} || 5; # Number of posts per page
  my $username   = route_parameters->{'username'};
  my ( $user )   = resultset('Users')->match_lc( $username );

  if ($user) {

    my @blog_owners = resultset('BlogOwner')->search({ user_id => $user->id });
    my @blogs;
    for my $blog_owner ( @blog_owners ) {
      push @blogs, map { $_->as_hashref_sanitized }
                   resultset('Blog')->find({ id => $blog_owner->blog_id });
    }
    my @posts = resultset('Post')->search_published({ user_id => $user->id });
    my @post_tags;
    for my $post ( @posts ) {
      push @post_tags, map { $_->as_hashref_sanitized } $post->tag_objects;
    }
    for my $blog ( @blogs ) {
      $blog->{count} = {
        owners => 1,
        post   => scalar @posts,
        tag    => scalar @post_tags,
      };
      $blog->{post_tags} = \@post_tags;
    }

    my $template_data = {
      blogs      => \@blogs,
      blog_count => scalar @blogs,
      user       => $user->as_hashref_sanitized,
    };

    if (param('format')) {
      my $json = JSON->new;
      $json->allow_blessed(1);
      $json->convert_blessed(1);
      $json->encode( $template_data );
    }
    else {
      template 'profile/author', $template_data;
    }
  }
  else {
    template 'profile/author';
  }

};

=head2 /profile route

=cut

post '/profile' => sub {

  my $params      = body_parameters;
  my $user        = session('user');
  my $res_user    = resultset('Users')->find_by_session(session);
  unless ( $res_user and $res_user->can_do( 'update user' ) ) {
    warn "***** Redirecting guest away from /profile";
    return template 'profile', {
      warning => "You are not allowed to update this user"
    }, { layout => 'admin' };
  }

  my $new_columns = { };
  my @message;

  if ($params->{'email'}) {
    my $existing_user =
      resultset('Users')->search({ email => $params->{'email'} })->count;
    if ($existing_user > 0) {
      push @message, "A user with this email address already exists.";
    }
    else {
      $new_columns->{'email'} = $params->{'email'};
    }
  }

  if ($params->{'username'}) {
    my $existing_user =
      resultset('Users')->search({ username => $params->{'username'} })->count;
    if ($existing_user > 0) {
       push @message, "A user with this username already exists.";
    }
    else {
      $new_columns->{'username'} = $params->{'username'};
    }
  }

  if ($params->{'displayname'}) {
    my $existing_user =
      resultset('Users')->search({ name => $params->{'displayname'} })->count;
    if ($existing_user > 0) {
      push @message, "A user with this displayname already exists.";
    }
    else {
      $new_columns->{'name'} = decode_utf8($params->{'displayname'});
    }
  }

  if ($params->{'about'}) {
    $new_columns->{'biography'} = decode_utf8($params->{'about'});
  }

  if (keys %$new_columns) {
    $res_user->update( $new_columns );
    $user->{$_} = $new_columns->{$_} for keys %$new_columns;
    session('user', $user);

    if ( !@message ) {
      template 'profile',
        { success => "Everything was successfully updated." }
    }
    else {
      template 'profile',
        { warning => "Some fields were updated, but ". join( "\n", @message ) }
    }
  }
  else {
    template 'profile',
      { warning => "No fields changed" }
  }
};

=head2 /profile-image route

=cut

any '/profile-image' => sub {

  my $params   = params;
  my $file     = $params->{file};
  my $user     = session('user');
  my $res_user = resultset('Users')->find_by_session(session);
  unless ( $res_user and $res_user->can_do( 'update user' ) ) {
    warn "***** Redirecting guest away from /profile-image";
    return template 'profile', {
      warning => "You are not allowed to update this user"
    }, { layout => 'admin' };
  }

  my $message;
  my $size_flag = 1;
  # The request has the size set in bytes and in our case
  # 4 MB = 4 * 1024 * 1024 =  4,194,304 bytes. (1 mb = 1024 kb, 1 kb = 1024 bytes)
  if (( request->uploads->{file}->{size} )> 4194304 ){
    $size_flag  = 0; 
  }
  my $upload_dir  = "/" . config->{'avatar'}{'path'};
  my $folder_path = config->{user_pics};
  my $filename    = sprintf( config->{'avatar'}{'format'}, $res_user->id );
  my $scale       = {
    xpixels => config->{avatar}{bounds}{width},
    ypixels => config->{avatar}{bounds}{height},
  };
  if ($size_flag){
    if ( $params->{action_form} eq 'crop' ) {
      if ( $params->{width} > 0 ) {
        if ( $params->{file} ) {
          my $logo = PearlBee::Helpers::ProcessImage->new(
            request->uploads->{file}->tempname
          );
          try {
            $logo->resize( $params, $scale, $folder_path, $filename );
          }
          catch {
            info 'There was an error resizing your avatar: ' . Dumper $_;
          };
        }
        else {
          my $logo = PearlBee::Helpers::ProcessImage->new(
            $folder_path . '/' . $filename
          );
          $logo->resize( $params, $scale, $folder_path, $filename );
        }
      }

      $res_user->update({ avatar_path => $upload_dir . $filename });
      $user->{avatar_path} = $upload_dir . $filename;
      $message = "Your profile picture has been changed.";
    }
    elsif ( $params->{action_form} eq 'delete' ) {
      $res_user->update({ avatar_path => '' });

      $message = "Your picture has been deleted";
    }
  }
  else {
    $message = 'The picture must be maximum 4MegaBytes';
  }

  session( 'user', $res_user->as_hashref_sanitized );
  if ($size_flag){
    template 'profile',
      {
        success => $message
      };
  }
  else {
    template 'profile',
    {
      error => $message
    };
  }
};

=head2 /blog-image/:size/blog/:blogname

=cut

any '/blog-image/:size/blog/:blogname' => sub {
  
  my $size        = route_parameters->{'size'};
  my $blogname    = route_parameters->{'blogname'};
  utf8::decode($blogname);
  my $file        = params->{'file'};
  my $upload_dir  = "/" . config->{'blog-avatar'}{'path'};
  my $folder_path = config->{'blog_pics'};
  my $user        = resultset('Users')->find_by_session(session);
  my $params      = params;
  
  my @timezones = DateTime::TimeZone->all_names;
  my $user_obj  = resultset('Users')->find_by_session(session);
  
  my @blogs;
  my $flag = 0;
  my $blog = resultset('Blog')-> find({
              name => $blogname
  });

  my $size_flag = 1;
  # The request has the size set in bytes and in our case
  # 4 MB = 4 * 1024 * 1024 =  4,194,304 bytes. (1 mb = 1024 kb, 1 kb = 1024 bytes)
  if (( request->uploads->{file}->{size} )> 4194304 ){
    $size_flag  = 0; 
  }

  if (!$user->is_admin){

    my @blog_owners = resultset('BlogOwner')->search({user_id => $user_obj->id});
    for my $blog_owner (@blog_owners){
      push @blogs, resultset('Blog')->search({ id => $blog_owner->get_column('blog_id')});
    }
    @blogs = map { $_->as_hashref } @blogs;

    unless ( $user and $user->can_do( 'update blog' ) ) {
      warn "***** Redirecting guest away from /blog-image/slug/:slug/user/:username'";
      return template 'blog', {
        warning => "You are not allowed to update this user"
      }, { layout => 'admin' };
    }
    my $entry = resultset('BlogOwner')-> find({
                blog_id => $blog->id,
                user_id => $user->id,
                });
    if ($entry->is_admin) {
      $flag = 1;
    }
   
  }
  else {

    @blogs = resultset('Blog')->all();
    $flag = 1;
  }

  if ( $blog && $flag && $size_flag)   {
    my $message  = "Your profile picture has been changed.";
    my $filename = sprintf( config->{'blog-avatar'}{'format'},
                            $size,
                            $blog->id );
    my $scale    = {
      xpixels => config->{'blog-avatar'}{'bounds'}{'width'},
      ypixels => config->{'blog-avatar'}{'bounds'}{'height'},
    };

    my $blog_column =
      $size eq 'large' ? 'large_avatar_path' : 'small_avatar_path';
    if ( $params->{action_form} eq 'crop' ) {
      if ( $params->{width} > 0 ) {
        if ( $params->{file} ) {
          my $logo = PearlBee::Helpers::ProcessImage->new(
            request->uploads->{file}->tempname
          );
          try {
            $logo->resize( $params, $scale, $folder_path, $filename );
          }
          catch {
            info 'There was an error resizing your avatar: ' . Dumper $_;
          };
        }
        else {
          my $logo = PearlBee::Helpers::ProcessImage->new(
            $folder_path . '/' . $filename
          );
          $logo->resize( $params, $scale, $folder_path, $filename );
        }
      }

      $blog->update({ $blog_column => $upload_dir . $filename });
      $blog->{$blog_column} = $upload_dir . $filename;
    }
    elsif ( $params->{action_form} eq 'delete' ) {
      $blog->update({ $blog_column => '' });

      $message = "Your picture has been deleted";
    }

    template 'admin/settings/index',
      {
        timezones     => \@timezones,
        blogs         => \@blogs,
        success       => $message,
        selected_blog => $blog
      },
      { layout => 'admin' };
  }
  elsif ( !($flag) ) {
    template 'admin/settings/index',
      {
        timezones => \@timezones,
        blogs     => \@blogs,
        warning => "You do not have the right to perform this action on the blog '$blogname' "
      },
      { layout => 'admin' };
  }
  elsif ( !($size_flag) ){
      template 'admin/settings/index',
      {
        timezones => \@timezones,
        blogs     => \@blogs,
        warning => " Your picture must be maximum 4 MegaBytes. "
      },
      { layout => 'admin' };
  }
  else {
        template 'admin/settings/index',
      {
        timezones => \@timezones,
        blogs     => \@blogs,
        warning => "Could not find a blog for with that name '$blogname' "
      },
      { layout => 'admin' };
  }
};

=head2 /profile_password route

=cut

post '/profile_password' => sub {
  my $params   = body_parameters;
  my $user     = session('user');
  my $res_user = resultset('Users')->find_by_session(session);
  unless ( $res_user and $res_user->can_do( 'update user' ) ) {
    warn "***** Redirecting guest away from /profile_password";
    return template 'profile', {
      warning => "You are not allowed to update this user",
    }, { layout => 'admin' };
  }

  my $template_data;

  if (defined($res_user) && ($params->{'new_password'} ne '')) {

    if ($params->{'new_password'} eq $params->{'confirm_password'}) {

      if ($res_user->validate($params->{'old_password'})) {

        my $hashed_password =
          crypt( $params->{'new_password'}, $res_user->password );
        $res_user->update({
          password => $hashed_password,
        });

        $template_data = { success => "You can now use your new password" };

      }
      else {
        $template_data =
          {
            warning => "Please enter your old password correctly",
          };
      }
    }
    else {
      $template_data =
        {
          warning => "Confirmation password was entered incorrectly",
        };
    }

  }
  else {
    $template_data = { warning => "No new password was entered" };
  }

  template 'profile', $template_data;
};

=head2 /profile_password route

=cut

get '/profile_password' => sub {

   template 'profile';

};

1;
