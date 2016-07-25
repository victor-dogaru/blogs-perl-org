package PearlBee::Author::User;

use Dancer2;
use Dancer2::Plugin::DBIC;
use PearlBee::Dancer2::Plugin::Admin;

use PearlBee::Helpers::Pagination qw(get_total_pages get_previous_next_link generate_pagination_numbering);
use PearlBee::Helpers::Util qw(create_password);

use Email::Template;
use DateTime;
use Data::Dumper;

get '/author/users' => sub { redirect '/author/users/page/1'; };

=head2 /author/users/page/:page

List all users contributing or owning the blogs in which the user is involved.

=cut

get '/author/users/page/:page' => sub {

  my $nr_of_rows = 5; # Number of posts per page
  my $page       = params->{page} || 1;
  my $user_obj   = resultset('Users')->find_by_session(session);
  unless ( $user_obj and $user_obj->id ) {
    warn "***** Redirecting guest away from /author/users/page/:page";
    redirect '/'
  }
  my @users;
  my @blogs;
  my @blogs_aux;
  my @blog_owners = resultset('BlogOwner')->search({user_id => $user_obj->id, is_admin=>1});
  for my $blog_owner (@blog_owners){
    push @blogs, 
                  resultset('Blog')->search({ id => $blog_owner->get_column('blog_id')});
  }

  for my $blog (@blogs){
    my @tmp_blogs      = resultset('BlogOwner')->search(
    { blog_id => $blog->get_column('id') });
    $_->{blog_name}    = $blog->name for @tmp_blogs;
    $_->{blog_slug}    = $blog->slug for @tmp_blogs;
    $_->{blog_creator} = $blog->blog_creator->username for @tmp_blogs;
    push @blogs_aux, @tmp_blogs;
  }

  for my $iterator (@blogs_aux){
    my @tmp_users      = map {$_->as_hashref_sanitized}
              resultset('Users')->search({ id => $iterator->get_column('user_id') });      
    $_->{role_in_blog} = $iterator->is_admin for @tmp_users;
    $_->{blog_name }   = $iterator->{blog_name} for @tmp_users;
    $_->{blog_slug }   = $iterator->{blog_slug} for @tmp_users;
    $_->{blog_creator} = $iterator->{blog_creator} for @tmp_users;
    $_->{can_change}   = resultset('BlogOwner')->find(
    {blog_id => $iterator->blog_id, user_id =>$user_obj->id})->is_admin for @tmp_users; 
    push @users, @tmp_users;
  }

  my $count      = resultset('View::Count::StatusUserNonAdmin')->find({}, { bind => [ $user_obj->id, 1 ] });
  my ($all, $active, $inactive, $suspended, $pending) = $count->get_all_status_counts;


  # Calculate the next and previous page link
  my $total_pages                 = get_total_pages($all, $nr_of_rows);
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/author/users');

  # Generation of the pagination navigation
  my $total_users    = $all;
  my $posts_per_page = $nr_of_rows;
  my $current_page   = $page;
  my $pages_per_set  = 7;
  my $pagination     = generate_pagination_numbering($total_users, $posts_per_page, $current_page, $pages_per_set);
  my @actual_users   = splice(@users,($page-1)*$nr_of_rows,$nr_of_rows);

  template 'admin/users/list',
    {
      users         => \@actual_users,
      blogs         => \@blogs,
      all           => $all, 
      active        => $active,
      inactive      => $inactive,
      suspended     => $suspended,
      pending       => $pending,
      page          => $page,
      next_link     => $next_link,
      previous_link => $previous_link,
      action_url    => 'author/users/page',
      pages         => $pagination->pages_in_set
    },
    { layout => 'admin' };

};

=head2 /author/users/:status/page/:page

Users  grouped by status

=cut

get '/author/users/:status/page/:page' => sub {

  my $nr_of_rows = 5; # Number of posts per page
  my $page       = params->{page} || 1;
  my $status     = params->{status};
  my $user_obj    = resultset('Users')->find_by_session(session);
  my @blogs;
  my @blogs2;
  my @users;
  my @blog_owners = resultset('BlogOwner')->search({user_id => $user_obj->id});
  for my $blog_owner (@blog_owners){
    push @blogs, 
                  resultset('Blog')->search({ id => $blog_owner->get_column('blog_id')});
  }

  for my $blog (@blogs){
    push @blogs2,
    resultset('BlogOwner')->search ({ blog_id => $blog->get_column('id') });
  }

  for my $blog (@blogs2){
    my @tmp_users = map {$_->as_hashref_sanitized}
              resultset('Users')->search({ id => $blog->get_column('user_id') });      
    $_->{role_in_blog} = $blog->is_admin for @tmp_users;
    push @users, @tmp_users;
  }

  my $count      = resultset('View::Count::StatusUserNonAdmin')->find({}, { bind => [ $user_obj->id ] });

  my ($all, $active, $inactive, $suspended, $pending) =
    $count->get_all_status_counts;
  my $status_count =
    $count->get_status_count($status);
  if (! session('multiuser')) {
    # do not count 'pending' users
    my $count_pending = resultset('Users')->search({ status => 'pending' })->count;
    $all -= $count_pending;
  }

  # Calculate the next and previous page link
  my $total_pages                 = get_total_pages($all, $nr_of_rows);
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/author/users/' . $status);

  # Generating the pagination navigation
  my $total_users     = $status_count;
  my $posts_per_page  = $nr_of_rows;
  my $current_page    = $page;
  my $pages_per_set   = 7;
  my $pagination      = generate_pagination_numbering($total_users, $posts_per_page, $current_page, $pages_per_set);

  template 'admin/users/list',
    {
      users         => \@users,
      blogs         => \@blogs,
      all           => $all, 
      active        => $active,
      inactive      => $inactive,
      suspended     => $suspended,
      pending       => $pending,
      page          => $page,
      next_link     => $next_link,
      previous_link => $previous_link,
      action_url    => 'author/users/' . $status . '/page',
      pages         => $pagination->pages_in_set,
      status        => $status
    },
    { layout => 'admin' };

};

=head2 /author/users/role/:role/page/:page

List all users grouped by role

=cut

get '/author/users/role/:role/page/:page' => sub {

  my $nr_of_rows = 5; # Number of posts per page
  my $page       = params->{page} || 1;
  my $role      = params->{role};
  my $flag;
  if ($role eq 'admin') {
    $flag = 1;
  }
    else {
      $flag=0; 
    }
  my $user_obj    = resultset('Users')->find_by_session(session);
  my @blogs;
  my @blogs2;
  my @users;
  my @blog_owners = resultset('BlogOwner')->search({user_id => $user_obj->id});
  for my $blog_owner (@blog_owners){
    push @blogs, 
                  resultset('Blog')->search({ id => $blog_owner->get_column('blog_id')});
  }

  for my $blog (@blogs){
    push @blogs2,
    resultset('BlogOwner')->search ({ blog_id => $blog->get_column('id'), is_admin =>$flag  });
  }

  for my $blog (@blogs2){
    my @tmp_users = map {$_->as_hashref_sanitized}
              resultset('Users')->search({ id => $blog->get_column('user_id') });      
    $_->{role_in_blog} = $blog->is_admin for @tmp_users;
    push @users, @tmp_users;
  }
  my $all = scalar @users;

  # Calculate the next and previous page link
  my $total_pages                 = get_total_pages($all, $nr_of_rows);
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/author/users/role/' . $role);

  # Generating the pagination navigation
  my $total_users     = $all;
  my $posts_per_page  = $nr_of_rows;
  my $current_page    = $page;
  my $pages_per_set   = 7;
  my $pagination      = generate_pagination_numbering($total_users, $posts_per_page, $current_page, $pages_per_set);

  template 'admin/users/list',
    {
      users         => \@users,
      blogs         => \@blogs,
      all           => $all, 
      page          => $page,
      next_link     => $next_link,
      previous_link => $previous_link,
      action_url    => 'author/users/role/' . $role . '/page',
      pages         => $pagination->pages_in_set,
      role          => $role
    },
    { layout => 'admin' };

};

=head2 /author/users/blog/:blog/page/:page

List all users grouped by blog's name, role and status.

=cut

get '/author/users/blog/:blog/page/:page' => sub {


  my $nr_of_rows = 5; # Number of posts per page
  my $page       = params->{page} || 1;
  my $blog       = resultset('Blog')->find({ name => params->{blog} });
  my $status     = params->{status};
  my $role       = params->{role};
  my $flag;
  if ($role eq 'admin') {
    $flag = 1;
  }
    else {
     $flag = 0; 
  }
  my $user_obj   = resultset('Users')->find_by_session(session);
  my @blogs;
  my @blogs_aux;
  my @users;
  my @blog_owners = resultset('BlogOwner')->search({user_id => $user_obj->id, is_admin=>1});
  
  for my $blog_owner (@blog_owners){
    if (params->{blog} ne 'all'){
      push @blogs, 
                  resultset('Blog')->search({ 
                      id => $blog_owner->get_column('blog_id'), 
                      name => params->{blog}
                      }
                    );
    }
    else {
      push @blogs, 
        resultset('Blog')->search({ 
            id => $blog_owner->get_column('blog_id') 
          }
        );
    }
  }

  for my $blog (@blogs){
    my @tmp_blogs      = resultset('BlogOwner')->search (
    { blog_id => $blog->get_column('id') });  
    $_->{blog_name}    = $blog->name for @tmp_blogs;
    $_->{blog_slug}    = $blog->slug for @tmp_blogs;
    $_->{blog_creator} = $blog->blog_creator->username for @tmp_blogs;
    push @blogs_aux, @tmp_blogs;
  }

  @blogs = map { $_->as_hashref } @blogs;

  my $filter = {};
  foreach my $iterator ( "is_admin", "status"){
      if (params->{$iterator} ne 'all'){
        $filter->{$iterator} = params->{$iterator};
      }
  }

  $filter->{"u.status"} = $filter->{status};
  undef $filter->{status};
  delete $filter->{status};

  push @blogs_aux, 
                resultset('BlogOwner')->search ({ 
                          blog_id => [map {$_->{id}} @blogs ],
                          %$filter
                        },
                        {
                          columns => [qw/blog_id user_id u.status is_admin /],
                          join => 'u',
                          result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                          
                        }
                      );


  foreach my $iterator (@blogs_aux){
    my @tmp_users       = map {$_->as_hashref_sanitized}
              resultset('Users')->search({ id => $iterator->{user_id} });      
    $_->{role_in_blog}  = $iterator->{is_admin} for @tmp_users;
    $_->{blog_name }    = $iterator->{blog_name} for @tmp_users;
    $_->{blog_slug }    = $iterator->{blog_slug} for @tmp_users;
    $_->{blog_creator } = $iterator->{blog_creator} for @tmp_users;
    $_->{can_change}    = resultset('BlogOwner')->find(
    { blog_id => $iterator->{blog_id}, user_id =>$user_obj->id})->is_admin for @tmp_users; 
    push @users, @tmp_users;
  }

  my $all = scalar @users;

  # Calculate the next and previous page link
  my $total_pages                 = get_total_pages($all, $nr_of_rows);
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/author/users/blog/' . $blog);

  # Generating the pagination navigation
  my $total_users     = $all;
  my $posts_per_page  = $nr_of_rows;
  my $current_page    = $page;
  my $pages_per_set   = 7;
  my $pagination      = generate_pagination_numbering($total_users, $posts_per_page, $current_page, $pages_per_set);
  my @actual_users    = splice(@users,($page-1)*$nr_of_rows,$nr_of_rows);

  template 'admin/users/list',
    {
      users         => \@actual_users,
      blogs         => \@blogs,
      all           => $all, 
      page          => $page,
      next_link     => $next_link,
      previous_link => $previous_link,
      action_url    => 'author/users/blog/' . params->{blog} . '/page',
      pages         => $pagination->pages_in_set,
      blog          => $blog->name
    },
    { layout => 'admin' };

};

=head2 /author/users/activate/:id

Activate user

=cut

any '/author/users/activate/:id' => sub {

  my $user_id = params->{id};
  my $user    = resultset('Users')->find( $user_id );

  try {
    $user->activate();
  }
  catch {
    info $_;
    error "Could not activate user";
  };

  redirect '/author/users';
};

=head2 /author/users/deactivate/:id

Deactivate user

=cut

any '/author/users/deactivate/:id' => sub {

  my $user_id          = params->{id};
  my $user             = resultset('Users')->find( $user_id );
  my $admin_user_count = resultset('Users')->search({ role => 'admin' })->count;

  if ( $user->is_admin and
       $admin_user_count <= 1 ) {
      error "Could not deactivate the only active user";
  }
  else {
    try {
      $user->deactivate();
    }
    catch {
      info $_;
      error "Could not deactivate user";
    };
  }

  redirect '/author/users';
};

=head2 /author/users/suspend/:id

Suspend user

=cut

any '/author/users/suspend/:id' => sub {

  my $user_id          = params->{id};
  my $user             = resultset('Users')->find( $user_id );
  my $admin_user_count = resultset('Users')->search({ role => 'admin' })->count;

  if ( $user->is_admin and
       $admin_user_count <= 1 ) {
      error "Could not suspend the only active user";
  }
  else {
    try {
      $user->suspend();
    }
    catch {
      info $_;
      error "Could not mark comment as pending for $user->{username}";
    };
  }

  redirect '/author/users';
};

=head2 /author/users/allow/:id

Allow pending user

=cut

any '/author/users/allow/:id' => sub {

  my $user_id = params->{id};
  my $user    = resultset('Users')->find( $user_id );
  my $res_user = resultset('Users')->find_by_session(session);
  unless ( $res_user and $res_user->can_do( 'update users' ) ) {
    warn "***** Redirecting unauthorized user away from /author/users/page/:page";
    redirect '/';
  }
  
  if ($user) {
    try {
      my $hashed_password = create_password();
      
      $user->update({ password => $hashed_password });
    
      $user->allow();
      
      Email::Template->send( config->{email_templates} . 'welcome.tt',
          {
              From    => config->{default_email_sender},
              To      => $user->email,
              Subject => config->{welcome_email_subject},
  
              tt_vars => {
                  role      => $user->role,
                  username  => $user->username,
                  password  => $hashed_password,
                  name      => $user->name,
                  app_url   => config->{app_url},
                  blog_name => session('blog_name'),
                  signature => config->{email_signature},
                  allowed   => 1,
              },
          });
    }
    catch {
      info "Error sending email: $_";
      error "Could not send the email";
    };
  }

  redirect '/author/users';
};

=head2 /author/users/add

Add a new user

=cut

any '/author/users/add' => sub {

  my $res_user     = resultset('Users')->find_by_session(session);
  unless ( $res_user and $res_user->can_do( 'create users' ) ) {
    warn "***** Redirecting unauthorized user away from /author/users/add";
    redirect '/'
  }

  if ( params->{username} ) {

    try {

      my $username = params->{username};
      my $email    = params->{email};
      my $name     = params->{name};
      my $role     = params->{role};

      resultset('Users')->create_hashed({
        username => $username,
        password => params->{password},
        name     => $name,
        role     => $role,
        email    => $email,
      });

      Email::Template->send( config->{email_templates} . 'welcome.tt',
        {
            From    => config->{default_email_sender},
            To      => $email,
            Subject => config->{welcome_email_subject},

            tt_vars => {
                role      => $role,
                username  => $username,
        	password  => params->{password},
                name      => $name,
                app_url   => config->{app_url},
                blog_name => session('blog_name'),
                signature => config->{email_signature}
            },
        }) or error "Could not send the email";
    }
    catch {
      error $_;
      template 'admin/users/add', 
        {
          warning => 'Something went wrong. Please contact the administrator.'
        }, 
        { layout => 'admin' };
    };

    template 'admin/users/add', 
      {
      success => 'The user was added succesfully and will be activated after he logs in.'
      }, 
      { layout => 'admin' };
  }
  else {
    template 'admin/users/add', {},  { layout => 'admin' };
  }  
};

=head2 /author/users/make_admin/:username/:blog

Set a contributor from your blogs to be an admin.

=cut

any '/author/users/make_admin/:username/:blog' => sub {

  my $user_obj   = resultset('Users')->find_by_session(session);
  unless ( $user_obj and $user_obj->id ) {
    warn "***** Redirecting guest away from /author/users/page/:page";
    redirect '/'
  }
  my $blog   = resultset('Blog')->find({ name =>params->{blog} });
  my $user   = resultset('Users')->find({ username=> params->{username}});
  my $action = resultset('BlogOwner')->find({user_id=>$user->id, blog_id=>$blog->id})
  ->update({ is_admin=>1 });
  redirect '/author/users';

};

=head2 /author/users/make_author/:username/:blog

Set a contributor from your blogs to be an author.

=cut

any '/author/users/make_author/:username/:blog' => sub {

  my $user_obj   = resultset('Users')->find_by_session(session);
  unless ( $user_obj and $user_obj->id ) {
    warn "***** Redirecting guest away from /author/users/page/:page";
    redirect '/'
  }
  my $blog   = resultset('Blog')->find({ name =>params->{blog} });
  my $user   = resultset('Users')->find({ username=> params->{username}});
  my $action = resultset('BlogOwner')->find({user_id=>$user->id, blog_id=>$blog->id})
  ->update({ is_admin=>0 });
  redirect '/author/users';

};

1;
