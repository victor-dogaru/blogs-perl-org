=head1

Author: Andrei Cacio
Email: andrei.cacio@evozon.com

=cut

package PearlBee::Admin::Comment;

use Try::Tiny;
use Dancer2;
use Dancer2::Plugin::DBIC;

use PearlBee::Dancer2::Plugin::Admin;

use PearlBee::Helpers::Pagination qw(get_total_pages get_previous_next_link generate_pagination_numbering);

=head2 /admin/comments ; /admin/comments/page/:page route

List all comments

=cut

get '/admin/comments' => sub { redirect '/admin/comments/page/1' };

get '/admin/comments/page/:page' => sub {

  my $nr_of_rows = 5; # Number of posts per page
  my $page       = params->{page} || 1;
  my @comments   = resultset('Comment')->search({}, { order_by => { -desc => "comment_date" }, rows => $nr_of_rows, page => $page });
  my $count      = resultset('View::Count::StatusComment')->first;
  my @blogs      = resultset('Blog')->all(); 

  my ($all, $approved, $trash, $spam, $pending) = $count->get_all_status_counts;

  # Calculate the next and previous page link
  my $total_pages                 = get_total_pages($all, $nr_of_rows);
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/admin/comments');

  # Generating the pagination navigation
  my $total_comments  = $all;
  my $posts_per_page  = $nr_of_rows;
  my $current_page    = $page;
  my $pages_per_set   = 7;
  my $pagination      = generate_pagination_numbering($total_comments, $posts_per_page, $current_page, $pages_per_set);

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
        action_url    => 'admin/comments/page',
        pages         => $pagination->pages_in_set
      },
      { layout => 'admin' };

};

=head2 /admin/comments/:status/page/:page

List all spam comments

=cut

get '/admin/comments/:status/page/:page' => sub {

  my $nr_of_rows = 5; # Number of posts per page
  my $page       = params->{page} || 1;
  my $status     = params->{status};
  my @comments   = resultset('Comment')->search({ status => $status  }, { order_by => { -desc => "comment_date" }, rows => $nr_of_rows, page => $page });
  my $count      = resultset('View::Count::StatusComment')->first;
  my @blogs      = resultset('Blog')->all(); 

  my ($all, $approved, $trash, $spam, $pending) = $count->get_all_status_counts;
  my $status_count                              = $count->get_status_count($status);

  # Calculate the next and previous page link
  my $total_pages                 = get_total_pages($all, $nr_of_rows);
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/admin/comments/' . $status );

  # Generating the pagination navigation
  my $total_comments  = $status_count;
  my $posts_per_page  = $nr_of_rows;
  my $current_page    = $page;
  my $pages_per_set   = 7;
  my $pagination      = generate_pagination_numbering($total_comments, $posts_per_page, $current_page, $pages_per_set);


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
        action_url    => 'admin/comments/' . $status . '/page',
        pages         => $pagination->pages_in_set
      },
      { layout => 'admin' };

};

=head2 /admin/comments/approve/:id

Accept comment

=cut

get '/admin/comments/approve/:id' => sub {

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

  redirect request()->{headers}->{referer};
};

=head2 /admin/comments/trash/:id

Trash a comment

=cut

get '/admin/comments/trash/:id' => sub {

  my $comment_id = params->{id};
  my $comment    = resultset('Comment')->find( $comment_id );
  my $user       = session('user');

  try {
    $comment->trash($user);
  }
  catch {
    info $_;
    error "Could not trash comment for $user->{username}";
  };

  redirect request()->{headers}->{referer};
};

=head2 /admin/comments/spam/:id

Spam a comment

=cut

get '/admin/comments/spam/:id' => sub {

  my $comment_id = params->{id};
  my $comment    = resultset('Comment')->find( $comment_id );
  my $user       = session('user');

  try {
    $comment->spam($user);
  }
  catch {
    info $_;
    error "Could not spam-bin comment for $user->{username}";
  };

  redirect request()->{headers}->{referer};
};

=head2 /admin/comments/pending/:id

Pending a comment

=cut

get '/admin/comments/pending/:id' => sub {

  my $comment_id = params->{id};
  my $comment    = resultset('Comment')->find( $comment_id );
  my $user       = session('user');

  try {
    $comment->pending($user);
  }
  catch {
    info $_;
    error "Could not spam-bin comment for $user->{username}";
  };

  redirect request()->{headers}->{referer};
};

=head2 /admin/comments/blog/:blog/:status/page/:page

List all comments grouped by blog and status.

=cut

get '/admin/comments/blog/:blog/:status/page/:page' => sub {

  my $nr_of_rows = 5; # Number of posts per page
  my $page       = params->{page} || 1;
  my $blog       = params->{blog};
  my $status     = params->{status};
  my $blog_ref;
  my @blog_posts;
  my @comments;
  my $user       = resultset('Users')->find_by_session(session);
  my @blogs      = resultset('Blog')->all();

  if (params->{blog} ne 'all'){
     $blog_ref   =resultset('Blog')->find({name => params->{blog}});
     @blog_posts = resultset('BlogPost')->search({ blog_id => $blog_ref->get_column('id')});
  }
  else
  {
    foreach my $iterator (@blogs){
      push @blog_posts, resultset('BlogPost')->search({ blog_id => $iterator->get_column('id')});
    }
  }

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
      push @comments, 
              resultset('Comment')->search({post_id => $blog_post->post_id});
    }
  }
  else{
    foreach my $blog_post (@blog_posts){
      push @comments, 
              resultset('Comment')->search({post_id => $blog_post->post_id, status => $status});
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
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/admin/comments/blog/' . $blog . '/'. $status);

  # Generating the pagination navigation
  my $total_comments  = $all;
  my $posts_per_page  = $nr_of_rows;
  my $current_page    = $page;
  my $pages_per_set   = 7;
  my $pagination      = generate_pagination_numbering($total_comments, $posts_per_page, $current_page, $pages_per_set);


  my @sorted_comments = sort {$b->id <=> $a->id} @comments;
  my @actual_comments = splice(@sorted_comments,($page-1)*$nr_of_rows,$nr_of_rows);
  map { $_->as_hashref } @actual_comments;
  
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
        action_url    => 'admin/comments/blog/' . $blog . '/' . $status . '/page',
        pages         => $pagination->pages_in_set
      },
      { layout => 'admin' };

};

1;
