package PearlBee::Routes::Avatar;

use Dancer2 0.163000;
use Dancer2::Plugin::DBIC;
use PearlBee::Helpers::Util qw(map_pages);
use PearlBee::Helpers::Pagination qw(get_total_pages get_previous_next_link);

our $VERSION = '0.1';

# Internal note here - Keep the Routes/ directory clean of little "handlers".
# Given the history of the application anything added here will be replicated
# all over h*ll.

get '/avatar-light' => sub { config->{'avatar'}{'default'}{'light'} };
get '/avatar-dark'  => sub { config->{'avatar'}{'default'}{'dark'}  };

=head2 /avatar/:combo-breaker/:username

Blog assets - XXX this should be managed by nginx or something.

=cut

get '/avatar/:combo_breaker/:username' => sub {
  my $username = route_parameters('username');

  redirect "/avatar/$username"
};

=head2 /avatar/ route

Avatar route that just returns the theme-based image

=cut

get '/avatar/' => sub {
  my $avatar_path = config->{'avatar'}{'default'}{'dark'};
  my $theme       = session( 'theme' ) || 'dark';

  if ( $theme eq 'light' ) {
    $avatar_path = config->{'avatar'}{'default'}{'light'}
  }

  send_file $avatar_path;
};

=head2 /avatar/:username route

Avatar username

=cut

get '/avatar/:username' => sub {
  my $username      = route_parameters->{'username'};
  my $user          = resultset( 'Users' )->find({ username => $username });
  my $avatar_config = config->{'avatar'};
  my $avatar_path   = $avatar_config->{'default'}{'dark'};
  my $theme         = session( 'theme' );

  if ( $user and $user->avatar_path and $user->avatar_path ne '' ) {
    my $path = $user->avatar_path;
    $avatar_path = $path if -e "public/$path";
  }
  elsif ( $theme and $theme eq 'light' ) {
    $avatar_path = $avatar_config->{'default'}{'light'}
  }

  return send_file $avatar_path;
};

=head2 /blog_avatar/:blogname route

Avatar for each blog

=cut

get '/blog_avatar/:blogname' => sub{
  my $blog_name = route_parameters->{'blogname'};
  my $avatar_config = config->{'blog-avatar'};
  utf8::decode($blog_name);
  my $blog      = resultset('Blog')->find ({ name => $blog_name});
  my $avatar_path   = $avatar_config->{'default'}{'dark'}{'large'};
  my $theme         = session( 'theme' );
  
  if ($blog->large_avatar_path ne ''){
    my $path = $blog->large_avatar_path;
    $avatar_path = $path if -e "public/$path";
  }
  elsif ( $theme and $theme eq 'light' ) {
    $avatar_path = $avatar_config->{'default'}{'light'}{'large'};
  }

  return send_file $avatar_path;
};

=head2 /blog_avatar/ route

Avatar route that just returns the theme-based blog image

=cut

get '/blog_avatar/' => sub{

  my $avatar_path = config->{'blog-avatar'}{'default'}{'dark'}{'large'};
  my $theme       = session( 'theme' );

  if ( $theme eq 'light' ) {
    $avatar_path = config->{'blog-avatar'}{'default'}{'light'}{'large'};
  }

  send_file $avatar_path;
};

1;
