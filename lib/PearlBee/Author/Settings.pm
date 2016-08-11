package PearlBee::Author::Settings;
use Try::Tiny;
use Dancer2;
use Dancer2::Plugin::DBIC;
use PearlBee::Dancer2::Plugin::Admin;


=head
  
 The method for updating a blog in which you are a owner. 

=cut 

post '/blog/profile' => sub {
  
  my @timezones   = DateTime::TimeZone->all_names;
  my @blogs; 
  my $params      = body_parameters;
  my $res_user    = resultset('Users')->find_by_session(session);
  my @blog_owners = resultset('BlogOwner')->search({user_id => $res_user->id});
  
  unless ( $res_user and $res_user->can_do( 'update blog' ) ) {
    return template 'author/settings', {
      warning   => "You are not allowed to update this blog",
    }, { layout => 'admin' };
  }
 
  my $new_columns = { };
  my @message;
  my $blog        = resultset('Blog')->find({ name => $params->{'current_name'} });
  my $flag        = resultset('BlogOwner')->find ({
                      blog_id =>$blog->id,
                      user_id=>$res_user->id
                      });

  if ($flag->is_admin){

    if ($params->{'blog_name'}){

      my $existing_blog = resultset('Blog')->search({ name => $params->{'blog_name'} })->count;
      if ($existing_blog > 0){
        push @message, "A blog with this name already exists.";
      }
      else {
        $new_columns->{'name'} = $params->{'blog_name'};
      }
    }

      if ($params->{'blog_description'}){

        $new_columns->{'description'} = $params->{'blog_description'};
      }

      if ($params->{'social_media'}){
            
          $new_columns->{'social_media'} = $params->{'social_media'};
      }
        
      if ($params->{'multiuser'}){
            
          $new_columns->{'multiuser'} = $params->{'multiuser'};
      }
         
      if ($params->{'accept_comments'}){
            
          $new_columns->{'accept_comments'} = $params->{'accepting_comments'};
      } 

      if ($params->{'timezone'}){
            
          $new_columns->{'timezone'} = $params->{'timezone'};
      }

      if (keys %$new_columns) {
      
        $blog->update( $new_columns );

        if ( !@message ) {

          for my $blog_owner (@blog_owners){
            push @blogs, resultset('Blog')->search({ 
                          id => $blog_owner->get_column('blog_id')
                          });
          }
          @blogs    = map { $_->as_hashref } @blogs;
          
          template 'admin/settings/index.tt', 
          {
          timezones => \@timezones,
          blogs     => \@blogs,
          success   => "Everything was successfully updated."
          },
          { layout  => 'admin' };
        }

        else {

          for my $blog_owner (@blog_owners){
            push @blogs, resultset('Blog')->search({ 
                        id => $blog_owner->get_column('blog_id')
                        });
          }
          @blogs    = map { $_->as_hashref } @blogs;     
          template 'admin/settings/index.tt', 
          {
          timezones => \@timezones,
          blogs     => \@blogs,
          warning   => "Some fields were updated, but ". join( "\n", @message ) 
          },
          { layout  => 'admin' };
        }
      }

      else {

        for my $blog_owner (@blog_owners){
          push @blogs, resultset('Blog')->search({ 
                       id => $blog_owner->get_column('blog_id')
                       });
        }
        @blogs    = map { $_->as_hashref } @blogs;     
        template 'admin/settings/index.tt', 
        {
        timezones => \@timezones,
        blogs     => \@blogs,
        warning   => "No fields changed"
        },
        { layout  => 'admin' };   
      }

  }
    else {
      for my $blog_owner (@blog_owners){
        push @blogs, resultset('Blog')->search({ 
                    id => $blog_owner->get_column('blog_id')
                    });
      }
      @blogs = map { $_->as_hashref } @blogs; 

      template 'admin/settings/index.tt', 
      {
      timezones => \@timezones,
      blogs     => \@blogs,
      warning   => "You are not an admin on that blog"
      },
      { layout => 'admin' };
    }
  
};

=head

Getter method so as to retrieve only those blogs in which you are an owner.

=cut

  get '/blog/profile' => sub {
    my @blogs;
    my $user      = resultset('Users')->find_by_session(session);
    my @blog_owners = resultset('BlogOwner')->search({ user_id => $user->id, is_admin => '1' });
    for my $blog_owner ( @blog_owners ) {
      push @blogs, map { $_->as_hashref }
                   resultset('Blog')->search({ id => $blog_owner->blog_id });
    }
      template 'author/settings',
    {
      blogs         => \@blogs
    },
    { layout => 'admin' };
  };



=head2 /author/settings route

Index of settings page

=cut

get '/author/settings' => sub {

  my $settings  = resultset('Setting')->first;
  my @timezones = DateTime::TimeZone->all_names;
  my $user_obj  = resultset('Users')->find_by_session(session);
  my @blogs;
  my @blog_owners = resultset('BlogOwner')->search({user_id => $user_obj->id});
  for my $blog_owner (@blog_owners){
    push @blogs, resultset('Blog')->search({ id => $blog_owner->get_column('blog_id')});
  }
  @blogs = map { $_->as_hashref } @blogs;

  template 'admin/settings/index.tt', 
    { 
      setting   => $settings,
      blogs     => \@blogs,
      timezones => \@timezones,
      blogs     => \@blogs
    }, 
    { layout => 'admin' };
};

1;
