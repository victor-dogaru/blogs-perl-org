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
  utf8::decode($params->{'current_name'});
  my $blog        = resultset('Blog')->find({ name => $params->{'current_name'} });
  my $owner       = resultset('BlogOwner')->find ({
                      blog_id =>$blog->id,
                      user_id=>$res_user->id
                      });
  my $flag = 0;
  my $check = length $params->{'blog_name'};
  if ($res_user->is_admin){
    $flag = 1;
    @blogs = resultset('Blog')->all();
  }
  else{
      my $owner       = resultset('BlogOwner')->find ({
                      blog_id =>$blog->id,
                      user_id=>$res_user->id
                      });
      if ($owner->is_admin) {
        $flag = 1;
      }
  }

  my @special_characters = ('#','\\','/');
  my $result ;
  my $special_char = 0;
  foreach my $iterator (@special_characters){
    $result = index($params->{blog_name},$iterator);
    if ($result >= 0) {
      $special_char = 1;
      last;
    }
  }

  if ($flag && !$special_char && $check<30){

    if ($params->{'blog_name'}){
      utf8::decode($params->{'blog_name'});
      my $existing_blog = resultset('Blog')->search({ name => $params->{'blog_name'} })->count;
      if ($existing_blog > 0){
        push @message, "A blog with this name already exists.";
      }
      else {
        $new_columns->{'name'} = $params->{'blog_name'};
      }
      }

      if ($params->{'blog_description'}){
        utf8::decode($params->{'blog_description'});
        $new_columns->{'description'} = $params->{'blog_description'};
      }

      if ($params->{'social_media'} eq 'on'){
            
          $new_columns->{'social_media'} = 1;
      }
      else{
        $new_columns->{'social_media'} = 0;
      }
        
      if ($params->{'multiuser'} eq 'on'){
            
          $new_columns->{'multiuser'} = 1;
      }
      else{
        $new_columns->{'multiuser'} = 0;
      }
         
      if ($params->{'accepting_comments'} eq 'on'){
            
          $new_columns->{'accept_comments'} = 1;
      }
      else{
        $new_columns->{'accept_comments'} = 0;
      }

      if ($params->{'timezone'}){
            
          $new_columns->{'timezone'} = $params->{'timezone'};
      }

      if (keys %$new_columns) {
      
        $blog->update( $new_columns );

        if ( !@message ) {
            if (!$res_user->is_admin){
              for my $blog_owner (@blog_owners){
                push @blogs, resultset('Blog')->search({ 
                              id => $blog_owner->get_column('blog_id')
                              });
              }
              @blogs    = map { $_->as_hashref } @blogs;
            }
          template 'admin/settings/index.tt', 
          {
          timezones => \@timezones,
          blogs     => \@blogs,
          success   => "Everything was successfully updated."
          },
          { layout  => 'admin' };
        }

        else {
          if (!$res_user->is_admin){
            for my $blog_owner (@blog_owners){
                push @blogs, resultset('Blog')->search({ 
                            id => $blog_owner->get_column('blog_id')
                            });
              }          
            @blogs    = map { $_->as_hashref } @blogs;
          }     
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
        if (!$res_user->is_admin){
          for my $blog_owner (@blog_owners){
            push @blogs, resultset('Blog')->search({ 
                         id => $blog_owner->get_column('blog_id')
                         });
          }
          @blogs    = map { $_->as_hashref } @blogs;  
        }   
        template 'admin/settings/index.tt', 
        {
        timezones => \@timezones,
        blogs     => \@blogs,
        warning   => "No fields changed"
        },
        { layout  => 'admin' };   
      }

  }
    elsif ($special_char){
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
      warning   => "Special characters (like the pound sign)  are not allowed."
      },
      { layout => 'admin' };
    }
    elsif ($check>30){
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
      warning   => "The blog name must not exceed 40 characters"
      },
      { layout => 'admin' };
    }
    else {
      if (!$res_user->is_admin){
      for my $blog_owner (@blog_owners){
        push @blogs, resultset('Blog')->search({ 
                    id => $blog_owner->get_column('blog_id')
                    });
      }
      @blogs = map { $_->as_hashref } @blogs; 
      }
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
