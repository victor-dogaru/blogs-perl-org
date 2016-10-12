package PearlBee::Author::Comment;

use Try::Tiny;
use Dancer2;
use Dancer2::Plugin::DBIC;
use PearlBee::Dancer2::Plugin::Admin;

use PearlBee::Helpers::Pagination qw(get_total_pages get_previous_next_link generate_pagination_numbering);

=head2 /author/comments ; /author/comments/page/:page

List all comments

=cut

get '/author/comments' => sub { redirect '/author/comments/page/1'; };

get '/author/comments/page/:page' => sub {

  my $nr_of_rows = 5; # Number of posts per page
  my $page       = params->{page} || 1;
  my @blogs;
  my $user        = resultset('Users')->find_by_session(session);
  my @comments    = resultset('View::UserComments')->search({}, { bind => [ $user->id ], order_by => \"comment_date DESC", rows => $nr_of_rows, page => $page });
  my $count       = resultset('View::Count::StatusCommentAuthor')->search({}, { bind => [ $user->id ] })->first;
  my @blog_owners = resultset('BlogOwner')->search({ user_id => $user->id });
  for my $blog_owner ( @blog_owners ) {
      push @blogs, map { $_->as_hashref }
                   resultset('Blog')->search({ id => $blog_owner->blog_id });
  }
  my ($all, $approved, $trash, $spam, $pending) = $count->get_all_status_counts;
  my $now = DateTime->now;
  foreach my $iterator (@comments){
    my $comment      = resultset('Comment')->find ({ id => $iterator->id });

    my $notification = resultset('Notification')->search ({
                              name        => 'comment',  
                              generic_id  => $comment->id,
                              user_id     => $user->id,
                              viewed      => 0 })
                                ->update({ viewed=>1, read_date=> $now });
  }
  # Calculate the next and previous page link
  my $total_pages                 = get_total_pages($all, $nr_of_rows);
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/author/comments');

  # Generating the pagination navigation
  my $total_comments = $all;
  my $posts_per_page = $nr_of_rows;
  my $current_page   = $page;
  my $pages_per_set  = 7;
  my $pagination     = generate_pagination_numbering($total_comments, $posts_per_page, $current_page, $pages_per_set);

  template 'admin/comments/list',
      {
        comments      => \@comments,
        blogs         => \@blogs,
        all           => $all,
        approved      => $approved,
        spam          => $spam,
        pending       => $pending,
        trash         => $trash,
        page          => $page,
        next_link     => $next_link,
        previous_link => $previous_link,
        action_url    => 'author/comments/page',
        pages         => $pagination->pages_in_set
      },
      { layout => 'admin' };

};

=head2 /author/comments/:status/page/:page

List all comments grouped by status

=cut

get '/author/comments/:status/page/:page' => sub {

  my $nr_of_rows = 5; # Number of posts per page
  my $page       = params->{page} || 1;
  my $status     = params->{status};
  my $user       = resultset('Users')->find_by_session(session);
  my @comments   = resultset('View::UserComments')->search({ status => $status },  { bind => [ $user->id ], order_by => \"comment_date DESC", rows => $nr_of_rows, page => $page });
  my $count       = resultset('View::Count::StatusCommentAuthor')->search({}, { bind => [ $user->id ] })->first;

  my ($all, $approved, $trash, $spam, $pending) = $count->get_all_status_counts;
  my $status_count                              = $count->get_status_count($status);

  # Calculate the next and previous page link
  my $total_pages                 = get_total_pages($all, $nr_of_rows);
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/author/comments/' . $status);

  # Generating the pagination navigation
  my $total_comments  = $status_count;
  my $posts_per_page  = $nr_of_rows;
  my $current_page    = $page;
  my $pages_per_set   = 7;
  my $pagination      = generate_pagination_numbering($total_comments, $posts_per_page, $current_page, $pages_per_set);
  my @blogs;
  my @blog_owners = resultset('BlogOwner')->search({ user_id => $user->id });
  for my $blog_owner ( @blog_owners ) {
      push @blogs, map { $_->as_hashref }
                   resultset('Blog')->search({ id => $blog_owner->blog_id });
  }
  template 'admin/comments/list',
      {
        comments      => \@comments,
        blogs         => \@blogs,
        all           => $all,
        approved      => $approved,
        spam          => $spam,
        pending       => $pending,
        trash         => $trash,
        page          => $page,
        next_link     => $next_link,
        previous_link => $previous_link,
        action_url    => 'author/comments/' . $status . '/page',
        pages         => $pagination->pages_in_set
      },
      { layout => 'admin' };

};

=head2 /author/comments/blog/:blog/:status/page/:page

List all comments grouped by blog.

=cut

get '/author/comments/blog/:blog/:status/page/:page' => sub {

  my $nr_of_rows = 5; # Number of posts per page
  my $page       = params->{page} || 1;
  my $blog       = params->{blog};
  my $status     = params->{status};
  my $blog_ref;
  my @blog_posts;
  my $user       = resultset('Users')->find_by_session(session);
  my @blog_owners = resultset('BlogOwner')->search({ user_id => $user->id });
  if (params->{blog} ne 'all'){
     $blog_ref   =resultset('Blog')->find({name => params->{blog}});
     @blog_posts = resultset('BlogPost')->search({ blog_id => $blog_ref->get_column('id')});
  }
  else
  {
    foreach my $iterator (@blog_owners){
      push @blog_posts, resultset('BlogPost')->search({ blog_id => $iterator->get_column('blog_id')});
    }
  }
 
  my @comments_aux; 
  my @posts; 
  my @ids;

  foreach my $i (@blog_posts){
    push @posts, resultset ('Post')->search({ id => $i->post_id})
  };
  
  foreach my $i (@posts){
     if ($i->user_id == $user->id){
      push @ids, $i->id;
     }
  }

  if ($status eq ('all') ){
    foreach my $blog_post (@blog_posts){
      push @comments_aux, 
              resultset('Comment')->search({post_id => $blog_post->post_id});
    }
  }
  else{
    foreach my $blog_post (@blog_posts){
      push @comments_aux, 
              resultset('Comment')->search({post_id => $blog_post->post_id, status => $status});
    }
  }
  
  my $flag;     

  my @comments;
  if (params->{blog} ne 'all'){
    $flag = resultset('BlogOwner')->find({blog_id => $blog_ref->id, user_id=>$user->id});
    if ($flag->is_admin == 0){
      foreach (@comments_aux) {
        my $found_id = $_->post_id;
        if (( grep /$found_id/, @ids ) or  ($_->get_column('uid') == $user->id)){ 
          push @comments, $_;
        }
      }
    }
    else{
      @comments = @comments_aux;
    }
  }
  else{
    foreach my $iterator (@blog_owners){
    $flag = resultset('BlogOwner')->find({blog_id => $iterator->get_column('blog_id'), user_id=>$user->id});
    if ($flag->is_admin == 0){
      foreach (@comments_aux) {
        my $found_id = $_->post_id;
          if (( grep /$found_id/, @ids ) or  ($_->get_column('uid') == $user->id)){ 
            push @comments, $_;
            }
        }
    }
    else{
     @comments = @comments_aux;
     }
    } 
  }

  my $all       = scalar @comments;
  my $approved  = 0;
  my $spam      = 0;
  my $trash     = 0;
  my $pending   = 0;

  foreach my $iterator(@comments){
    if ($iterator->status eq 'approved')
    {
      $approved ++;
    }
    elsif ($iterator->status eq 'pending'){
      $pending++;
    }
    elsif ($iterator->status eq 'trash'){
      $trash++;
    }
    else{
      $spam++;
    }
  }

  # Calculate the next and previous page link
  my $total_pages                 = get_total_pages($all, $nr_of_rows);
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/author/comments/blog/' . $blog . '/'. $status);

  # Generating the pagination navigation
  my $total_comments  = $all;
  my $posts_per_page  = $nr_of_rows;
  my $current_page    = $page;
  my $pages_per_set   = 7;
  my $pagination      = generate_pagination_numbering($total_comments, $posts_per_page, $current_page, $pages_per_set);

  my @blogs;
 
  for my $blog_owner ( @blog_owners ) {
      push @blogs, map { $_->as_hashref }
                   resultset('Blog')->search({ id => $blog_owner->blog_id });
  }
  my $session_user      = session('user');
  foreach (@comments){
    my $comment = resultset('Comment')->find({ id=> $_->id });
    if( $comment->is_authorized($session_user)){
      $_->{is_admin} = 1;
    }
    else
    {
      $_->{is_admin} = 0;
    }   
  }
  my @sorted_comments = sort {$b->id <=> $a->id} @comments;
  my @actual_comments = splice(@sorted_comments,($page-1)*$nr_of_rows,$nr_of_rows);
  map { $_->as_hashref } @actual_comments;
  my $now = DateTime->now;
  foreach my $iterator (@actual_comments){
    my $comment      = resultset('Comment')->find ({ id => $iterator->id });

    my $notification = resultset('Notification')->search ({
                              name        => 'comment',  
                              generic_id  => $comment->id,
                              user_id     => $user->id,
                              viewed      => 0 })
                                ->update({ viewed=>1, read_date=> $now });
  }
  template 'admin/comments/list',
      {
        comments      => \@actual_comments,
        blogs         => \@blogs,
        searched_blog => $blog_ref,
        all           => $all,
        approved      => $approved,
        spam          => $spam,
        pending       => $pending,
        trash         => $trash,
        page          => $page,
        next_link     => $next_link,
        previous_link => $previous_link,
        action_url    => 'author/comments/blog/' . $blog . '/' . $status . '/page',
        pages         => $pagination->pages_in_set
      },
      { layout => 'admin' };

};

=head2 /author/comments/approve/:id

Accept comment

=cut

get '/author/comments/approve/:id' => sub {

  my $comment_id = params->{id};
  my $comment    = resultset('Comment')->find( $comment_id );
  my $user       = session('user');

  try {
    $comment->approve($user);
  }
  catch {
    info $_;
    error "Could not approve comment for $user->{username}";
  };

  redirect request->referer;
};

=head2 /author/comments/trash/:id

Trash a comment

=cut

get '/author/comments/trash/:id' => sub {

  my $comment_id = params->{id};
  my $comment    = resultset('Comment')->find( $comment_id );
  my $user       = session('user');

  try {
    $comment->trash($user);
  }
  catch {
    info $_;
    error "Could not mark comment as trash for $user->{username}";
  };

  redirect request->referer;
};

=head2 /author/comments/spam/:id

Spam a comment

=cut

get '/author/comments/spam/:id' => sub {

  my $comment_id = params->{id};
  my $comment    = resultset('Comment')->find( $comment_id );
  my $user       = session('user');

  try {
    $comment->spam($user);
  }
  catch {
    info $_;
    error "Could not mark comment as spam for $user->{username}";
  };

  redirect request->referer;
};

=head2 /author/comments/pending/:id

Pending a comment

=cut

get '/author/comments/pending/:id' => sub {

  my $comment_id = params->{id};
  my $comment    = resultset('Comment')->find( $comment_id );
  my $user       = session('user');

  try {
    $comment->pending($user);
  }
  catch {
    info $_;
    error "Could not mark comment as pending for $user->{username}";
  };

  redirect request->referer;
};

1;
