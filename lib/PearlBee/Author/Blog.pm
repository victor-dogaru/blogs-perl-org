package PearlBee::Author::Blog;

use Try::Tiny;
use Dancer2;
use Dancer2::Plugin::DBIC;
use PearlBee::Dancer2::Plugin::Admin;
use PearlBee::Helpers::Pagination qw(get_total_pages get_previous_next_link generate_pagination_numbering);

=head2 /author/blogs ; /author/blogs/page/:page

List all the blogs of an author.

=cut

get '/author/blogs' => sub { redirect '/author/blogs/page/1'; };

get '/author/blogs/page/:page' => sub {

  my $nr_of_rows = 5; # Number of posts per page
  my $page       = params->{page} || 1;
  my $user       = resultset('Users')->find_by_session(session);
  my @blogs      = resultset('View::UserBlogs')->search({}, { bind => [ $user->id ], order_by => \"created_date DESC", rows => $nr_of_rows, page => $page });
  my $count      = resultset('View::Count::StatusBlogAuthor')->search({}, { bind => [ $user->id ] })->first;
  my @actual_blogs;
  my ($all, $inactive, $active) = $count->get_all_status_counts;

  # Calculate the next and previous page link
  my $total_pages                 = get_total_pages($all, $nr_of_rows);
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/author/blogs');

  # Generating the pagination navigation
  my $total_blogs    = $all;
  my $posts_per_page = $nr_of_rows;
  my $current_page   = $page;
  my $pages_per_set  = 7;
  my $pagination     = generate_pagination_numbering($total_blogs, $posts_per_page, $current_page, $pages_per_set);
  foreach my $blog (@blogs){
  push @actual_blogs, 
                  resultset('Blog')->search({ id => $blog->id});
  }
  foreach my $blog (@actual_blogs){
  $blog->{role_in_blog} = resultset('BlogOwner')->find ({ blog_id =>$blog->id, user_id =>$user->id })->is_admin;
  }
  map { $_->as_hashref } @actual_blogs ;
  template 'admin/blogs/list',
      {
        blogs         => \@actual_blogs,
        all           => $all,
        active        => $active,
        inactive      => $inactive,
        page          => $page,
        next_link     => $next_link,
        previous_link => $previous_link,
        action_url    => 'author/blogs/page',
        pages         => $pagination->pages_in_set
      },
      { layout => 'admin' };

};

=head2 /author/blog/:blogname/delete ; 

delete a blog with all its posts, comments, ownership relations etc.

=cut

any '/author/blog/:blogname/delete' => sub{

  my $user  = resultset('Users')->find_by_session(session);
  my $blog  = resultset('Blog')->find ({ name=> params->{blogname} });
  my $flag  = resultset('BlogOwner')->search ({ 
                  user_id => $user->id,
                  blog_id => $blog->id,
                  is_admin=>1})->count();
  if ($user->is_admin) {
    $flag = 1;
  }

  if ($flag == 0 ){
    redirect '/author/blogs';
  }
  else {
    try{
      my @posts;
      my @blog_posts = resultset('BlogPost')->search({
        blog_id => $blog->id
        });

      foreach my $iterator (@blog_posts){
        push @posts, resultset('Post')->find({ id => $iterator->post_id});
      }
      
      foreach my $iterator (@posts){
        my @post_categories = resultset('PostCategory')->search ({
          post_id => $iterator->id
          })->delete();
      } 
      
      foreach my $iterator (@posts){
        my @post_tag = resultset('PostTag')->search ({
          post_id => $iterator->id
          })->delete();
      } 
      
      foreach my $iterator (@posts){
        my @comments = resultset('Comment')->search ({
          post_id => $iterator->id
          })->delete();
      } 
      my @blog_posts2 = resultset('BlogPost')->search({
        blog_id => $blog->id
        })->delete();

      foreach my $iterator (@blog_posts){
        my @posts = resultset('Post')->search({ id => $iterator->post_id })->delete();
      }
    
      my @blog_owners= resultset('BlogOwner')->search({
        blog_id => $blog->id
        })->delete();

      my @blog_pages= resultset('BlogPage')->search({
        blog_id => $blog->id
        })->delete();

      my @blog_categories= resultset('BlogCategories')->search({
        blog_id => $blog->id
        })->delete();

      $blog->delete();
    }  
    catch{
      error $_;
      };
  }
  if ($user->is_admin) {
    redirect request->referer;
  }
  else {
    redirect request->referer;
  }

};

1;
