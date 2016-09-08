package PearlBee::Blogs;

=head1 PearlBee::Blog

Blog routes

=cut

use Dancer2 0.163000;
use Dancer2::Plugin::DBIC;
use PearlBee::Helpers::Util qw(map_posts generate_hash );
use PearlBee::Helpers::Notification_Email;
use PearlBee::Helpers::Pagination qw(get_total_pages get_previous_next_link);
use DateTime::TimeZone;
use Try::Tiny;

our $VERSION = '0.1';

=head2 /blogs/user/:username/slug/:slug ; /users/:username

View blog posts by username and blog's slug and name.

=cut

#http://139.162.204.109:5030/blogs/user/pmurias/slug/a_blog_about_the_perl_programming_language

get '/users/:username' => sub {

  my $username = route_parameters->{'username'};
  my $slug     = 'foo';

  redirect "/blogs/user/$username/slug/$slug"
};

=head2 /blogs/user/:username/blogname/:name;

First page onto which we concatanate new jsons.

=cut

get '/blogs/user/:username/blogname/:name' => sub{
  my $num_user_posts =  10;
  my $blog_name   = route_parameters->{'name'};
  $blog_name =~ s/%20/ /g;
  my $username    = route_parameters->{'username'};
  my ( $user )    = resultset('Users')->match_lc( $username );
  my @blog_ids;
  my @posts;
  unless ($user) {
    return error "No such user '$username'";
  }
  my ( $searched_blog ) = resultset('Blog')->find_by_name_uid({
    name => $blog_name, user_id => $user->id
  });

  push @blog_ids, resultset('BlogPost')->search({ blog_id => $searched_blog->id });

  foreach my $iterator (@blog_ids){
    push @posts, resultset('Post')->search ({ 
      id => $iterator->post_id
      });
  }

  my $nr_of_posts = scalar @posts;
  # extract demo posts info
  my @sorted_posts = sort {$b->created_date <=> $a->created_date}@posts;


  
  my @aux_authors    = $searched_blog->contributors;
  $searched_blog     = $searched_blog->as_hashref_sanitized if $searched_blog;
  my @authors        = map { $_->as_hashref_sanitized } @aux_authors;
  my $total_pages                 = get_total_pages($nr_of_posts, $num_user_posts);

  #the map_posts method must be investigated and refined, so, for the moment, 
  #we'll make the splice on the sorted_posts array, NOT on the mapped_posts one
  my @actual_posts   = splice(@sorted_posts,0*$num_user_posts,$num_user_posts);


  my $template_data = 
      { 
        posts          => \@actual_posts,
        total_pages    => $total_pages,
        posts_for_user => $username,
        user           => $user,
        authors        => \@authors,
        searched_blog  => $searched_blog,
        nr_of_posts    => $nr_of_posts
    };

  template 'blogs', $template_data;

};

get '/blogs/user/:username/blogname/:name/page/:page' => sub {

  my $num_user_posts =  10;
  my $blog_name   = route_parameters->{'name'};
  $blog_name =~ s/%20/ /g;
  my $username    = route_parameters->{'username'};
  my ( $user )    = resultset('Users')->match_lc( $username );
  my @blog_ids;
  my @posts;
  unless ($user) {
    return error "No such user '$username'";
  }
  my ( $searched_blog ) = resultset('Blog')->find_by_name_uid({
    name => $blog_name, user_id => $user->id
  });

  push @blog_ids, resultset('BlogPost')->search({ blog_id => $searched_blog->id });

  foreach my $iterator (@blog_ids){
    push @posts, resultset('Post')->search ({ 
      id => $iterator->post_id
      });
  }

  my $nr_of_posts = scalar @posts;
  # extract demo posts info
  my @sorted_posts = sort {$b->created_date <=> $a->created_date}@posts;
  #my @mapped_posts = map_posts(@sorted_posts);
  my $movable_type_url = config->{movable_type_url};
  my $app_url = config->{app_url};

  # for my $post ( @mapped_posts ) {
  #   $post->{content} =~ s{$movable_type_url}{$app_url}g;
  # }

  # Calculate the next and previous page link
  my $total_pages                 = get_total_pages($nr_of_posts, $num_user_posts);
  my ($previous_link, $next_link) = get_previous_next_link
  (1, $total_pages, '/blogs/user/' . $username .'/blogname/'.$blog_name);
  
  my @aux_authors    = $searched_blog->contributors;
  $searched_blog     = $searched_blog->as_hashref_sanitized if $searched_blog;
  my @authors        = map { $_->as_hashref_sanitized } @aux_authors;
  my $page           = params->{page}; 
  #the map_posts method must be investigated and refined, so, for the moment, 
  #we'll make the splice on the sorted_posts array, NOT on the mapped_posts one
  my @actual_posts   = splice(@sorted_posts,($page-1)*$num_user_posts,$num_user_posts);
  my @mapped_posts = map_posts(@actual_posts);

  my $template_data = 
      {
        posts          => \@mapped_posts,
        page           => $page,
        total_pages    => $total_pages,
        next_link      => $next_link,
        previous_link  => $previous_link,
        posts_for_user => $username,
        user           => $user,
        authors        => \@authors,
        searched_blog  => $searched_blog,
        nr_of_posts    => $nr_of_posts
    };
  if ( param('format') ) {
    my $json = JSON->new;
    $json->allow_blessed(1);
    $json->convert_blessed(1);
    $json->encode( $template_data );
  }
  else {
    template 'blogs', $template_data;
  }
};

=head2 /blogs/user/:username/slug/:slug/page/:page route

 View posts for username by page

=cut

get '/blogs/user/:username/slug/:slug/page/:page' => sub {

  my $num_user_posts = config->{blogs}{user_posts} || 10;

  my $username    = route_parameters->{'username'};
  my $page        = route_parameters->{'page'};
  my ( $user )    = resultset('Users')->match_lc( $username );
  unless ($user) {
    # we did not identify the user
    error "No such user '$username'";
  }
  my @posts       = resultset('Post')->search_published({ 'user_id' => $user->id }, { order_by => { -desc => "created_date" }, rows => $num_user_posts, page => $page });
  my $nr_of_posts = resultset('Post')->search_published({ 'user_id' => $user->id })->count;
  my @tags        = map { $_->as_hashref_sanitized }
                    map { $_->tag_objects } @posts;
  my @categories  = map { $_->as_hashref_sanitized }
                    map { $_->category_objects } @posts;

  # extract demo posts info
  my @mapped_posts = map_posts(@posts);

  # Calculate the next and previous page link
  my $total_pages                 = get_total_pages($nr_of_posts, $num_user_posts);
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/posts/user/' . $username);

  my $template_data =
    {
      posts          => \@mapped_posts,
      tags           => \@tags,
      categories     => \@categories,
      page           => $page,
      total_pages    => $total_pages,
      next_link      => $next_link,
      previous_link  => $previous_link,
      posts_for_user => $username,
    };
  if ( param('format') ) {
    my $json = JSON->new;
    $json->allow_blessed(1);
    $json->convert_blessed(1);
    $json->encode( $template_data );
  }
  else {
    template 'blogs', $template_data;
  }
};

=head2 /blogs/slug/:slug/page/:page route

 View authors for a specific blog

=cut

get '/blogs/authors/slug/:slug/page/:page' => sub {

  my $num_authors = config->{blogs}{nr_of_authors} || 5;
  my $page        = route_parameters->{'page'};
  my $slug        = route_parameters->{'slug'};
  my @authors; my $owner;

  my $blog          = resultset('Blog')->find({ slug => $slug });
  my @blog_owners   = resultset('BlogOwner')->search ({ blog_id => $blog->id });
  my $nr_of_authors = resultset('BlogOwner')->search ({ blog_id => $blog->id })->count;

  for my $blog_owner (@blog_owners){
    push @authors, map { $_->as_hashref_sanitized } 
           resultset('Users')->search({ id => $blog_owner->get_column('user_id') });
   }

  # Calculate the next and previous page link
  my $total_pages                 = get_total_pages($nr_of_authors, $num_authors);
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/blogs/authors/slug/' . $slug);
  
  my $template_data =
    { 
      authors        => \@authors,
      page           => $page,
      total_pages    => $total_pages,
      next_link      => $next_link,
      previous_link  => $previous_link,
    };
  
  if ( param('format') ) {
    my $json = JSON->new;
    $json->allow_blessed(1);
    $json->convert_blessed(1);
    $json->encode( $template_data );
  }
  else {
    template 'blogs', $template_data;
  }
};

=head2 /create-blog

  Create a new blog by making the user a blog owner

=cut

post '/create-blog' => sub{

  my $params    = body_parameters;
  my @timezones = DateTime::TimeZone->all_names;
  my $user      = resultset('Users')->find_by_session(session);
  unless ( $user and $user->can_do( 'create blog' ) ) {
    if ( $user->id ) {
      my $id = $user->id;
      log "User ID $user tried to create a blog";
    }
    warn "***** Redirecting guest away from /create-blog";
    redirect '/'
  }

  my $flag = 0;
  my $check_blog = resultset('Blog')->find({ name=> $params->{blog_name}});
  if ($check_blog){
      $flag = 1;
  }
  
  if (!$flag ){
    try{
      my $blog = resultset('Blog')->create_with_slug({
        name            => $params->{blog_name},
        description     => $params->{blog_description},
        timezone        => $params->{timezone},
        slug            => $params->{blog_url},
        social_media    => $params->{newblog_social_media} eq 'on' ? 1 : 0,
        multiuser       => $params->{newblog_multiuser} eq 'on' ? 1 : 0 ,
        accept_comments => $params->{newblog_comments} eq 'on' ? 1 : 0,
      });

      my $blog_owner = resultset('BlogOwner')->create({
        blog_id   => $blog->id,
        user_id   => $user->id,
        is_admin  =>"true",
      });
    }
    catch{
      error $_;
    };
  }

  if ($flag){
  template 'admin/blogs/add',
   {    
    timezones => \@timezones,
    error     => 'There already exists a blog with this name.'
    },
    { layout  => 'admin' };
  }
  else {
    template 'admin/blogs/add', {
    timezones => \@timezones,
    success   => 'The blog was created.'
    },
     {layout  => 'admin' };
  }

};

=head2 admin/create-blog

  Getter for blog-creation for admins;

=cut

get 'admin/create-blog' => sub{
      my @blogs     = resultset('Blog')->all();
      my @timezones = DateTime::TimeZone->all_names;
      template 'admin/blogs/add',
      {
        blogs => \@blogs,
        timezones => \@timezones
      },
      { layout => 'admin' };
};

=head2 author/create-blog

  Getter for blog-creation for authors;

=cut

get 'author/create-blog' => sub{

      my $user       = resultset('Users')->find_by_session(session);
      my @timezones = DateTime::TimeZone->all_names;
      my @blogs;
      my @blog_owners = resultset('BlogOwner')->search({ user_id => $user->id });
      for my $blog_owner ( @blog_owners ) {
      push @blogs, map { $_->as_hashref }
                   resultset('Blog')->search({ id => $blog_owner->blog_id });
      }
      template 'admin/blogs/add',
      {
        blogs => \@blogs,
        timezones => \@timezones
      },
      { layout => 'admin' };
};

=head2 /add-contributor/blog
 
  Add a contributor, making her/him an admin or a simple author.

=cut

post '/add-contributor/blog' => sub {

    my $user        = resultset('Users')->find_by_session(session);
    my $params      = body_parameters;
    my $blogname    = $params->{'blog_name'};
    my $email       = $params->{'email'};
    my $role        = $params->{'role'};
    my $invitee     = resultset('Users')->find({ email => $email });
    my $blog        = resultset('Blog')->find({ name  => $blogname });
    my @blogs;
    my @blog_owners = resultset('BlogOwner')->search ({ 
                        user_id => $user->id,
                        is_admin=>1
                       });    
    foreach my $iterator (@blog_owners){
      push @blogs, map {$_ -> as_hashref}
                resultset('Blog')->search({ id => $iterator->blog_id }); 
    }
    my $date    = DateTime->now();
    my $token   = generate_hash( $email . $date );

    if ($invitee){
      my $flag    = 0;
      my $message = '';
      my $check   = resultset('BlogOwner')->search ({ 
                      user_id  => $user->id,
                      blog_id  => $blog->id,
                      is_admin =>1
                  })->count;

      if ( $check == 0 ) {
          $flag = 1;
          $message = 'You are not on admin on the blog '. $blogname ;       
        }
      
      my $check2  = resultset('BlogOwner')->search ({
                       blog_id => $blog->id, 
                       user_id => $invitee->id
                     })->count;

      if ( $check2 > 0 ){
          $flag = 1;
          $message = 'The user '.  $invitee->name . ' is already  on your blog!';      
        } 

      if ( $flag == 0) {

        my $blog_id = $blog->id;
        my $user_id = $user->id;

        my $blog_owner = resultset('BlogOwner')->create({
            user_id        => $invitee->id,
            blog_id        => $blog_id,
            is_admin       => $role eq 'admin' ? 1 : 0,
            status         => 'inactive', #
            # created_date defaults cleanly
            activation_key => $token,
        });
        my $notification = resultset('Notification')->create_invitation({
            blog_id => $blog_id,
            user_id => $invitee->id,
            old_status => 'unread',
            sender_id => $user->id,
            role     => $role
        });

        PearlBee::Helpers::Notification_Email->invite_contributor({
            user => $user,
            invitee => $invitee,
            config => config
        });

        template 'admin/users/add', {
          success => 'The user received an invitation successfully!',
          blogs   => \@blogs
        }, 
        { layout => 'admin' }; 
            
      }
      else {
        template 'admin/users/add', {
          warning => $message,
          blogs   => \@blogs
        }, 
        { layout => 'admin' }; 
      }
  }
  else{   

    my $notification = resultset('Notification')->create_invitation({
    blog_id => $blog->id,
    old_status => $email,
    role      =>$role,
    sender_id => $user->id,
    user_id   => '1'
    });

    PearlBee::Helpers::Email::send_email_complete({
       template => 'new_user.tt',
       from     => config->{default_email_sender},
       to       => $email,
       subject  => 'You have been invited on BPO',

       template_params => {
          config    => config,
          role      =>$role,
          blog      => $blog->name
       }
     });

    template 'admin/users/add', {
      warning => 'The user does not have an account. An  invitation mail has been sent to that address',
      blogs   => \@blogs
    }, 
    {layout => 'admin' }; 
  }
};

1;
