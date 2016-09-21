package PearlBee::Author::Tag;

use Try::Tiny;
use Dancer2;
use Dancer2::Plugin::DBIC;

use PearlBee::Dancer2::Plugin::Admin;

use PearlBee::Helpers::Util qw(string_to_slug);
use PearlBee::Helpers::Pagination qw(get_total_pages get_previous_next_link generate_pagination_numbering);


=head2 /author/tags/page/:page

List the tags which occur in the blogs in which the user is an owner or is contributing to.
Only 5 entries per page.

=cut

get '/author/tags' => sub{
  redirect '/author/tags/page/1';
};

get '/author/tags/page/:page' => sub { 
  
  my $nr_of_rows  = 5; # Number of posts per page
  my $page        = params->{page};
  my $user        = resultset('Users')->find_by_session(session);
  my @aux_tags    = resultset('Tag')->user_tags($user->id);

  my $all         = scalar (@aux_tags);
  my @sorted_tags = sort {$b->id <=> $a->id} @aux_tags;
  my @tags        = splice(@sorted_tags,($page-1)*$nr_of_rows,$nr_of_rows);

  
  my $total_pages                 = get_total_pages($all, $nr_of_rows);
  my ($previous_link, $next_link) = get_previous_next_link($page, $total_pages, '/author/tags');
  
  my $total_posts     = $all;
  my $posts_per_page  = $nr_of_rows;
  my $current_page    = $page;
  my $pages_per_set   = 5;
  my $pagination      = generate_pagination_numbering($total_posts, $posts_per_page, $current_page, $pages_per_set);


    template 'admin/tags/list',
    {
     all           => $all, 
     page          => $page,
     next_link     => $next_link,
     previous_link => $previous_link,
     action_url    => 'author/tags/page',
     pages         => $pagination->pages_in_set,
     tags          => \@tags 
    }, 
    { layout => 'admin' };
};

=head2 /author/tags/add

Add a new tag

=cut

any '/author/tags/add' => sub {

  my $name = params->{name};
  my $nr_of_rows = 5;
  my $slug = string_to_slug( params->{slug} );
  my $user = resultset('Users')->find_by_session(session);
  unless ( $user and $user->can_do( 'create tag' ) ) {
    warn "***** Redirecting guest away from /author/tags/add";
    return template 'admin/tags/list', {
      warning => "You are not allowed to create a tag",
    }, { layout => 'admin' };
  }
  my @aux_tags    = resultset('Tag')->user_tags($user->id);
  my $all         = scalar (@aux_tags);
  my @sorted_tags = sort {$b->id <=> $a->id} @aux_tags;
  my @tags        = splice(@sorted_tags,0*$nr_of_rows,$nr_of_rows);
  
  my $total_pages                 = get_total_pages($all, $nr_of_rows);
  my ($previous_link, $next_link) = get_previous_next_link(1, $total_pages, '/author/tags');  
  my $total_posts     = $all;
  my $posts_per_page  = $nr_of_rows;
  my $current_page    = 1;
  my $pages_per_set   = 5;
  my $pagination      = generate_pagination_numbering($total_posts, $posts_per_page, $current_page, $pages_per_set);
  my $check           = length ($name);
  my $found_slug_or_name = resultset('Tag')->search({ -or => [ slug => $slug, name => $name ] })->first;

  # Check for slug or name duplicates
  if ( $found_slug_or_name ) {
  template 'admin/tags/list',
    {
     warning       => 'The tag name or slug already exists',
     all           => $all, 
     page          => 1,
     next_link     => $next_link,
     previous_link => $previous_link,
     action_url    => 'author/tags/page',
     pages         => $pagination->pages_in_set,
     tags          => \@tags 
    }, 
    { layout => 'admin' };  }
    elsif ( $check>30 ) {
    template 'admin/tags/list',
    {
     warning       => 'The category name must not exceed 30 characters!',
     all           => $all, 
     page          => 1,
     next_link     => $next_link,
     previous_link => $previous_link,
     action_url    => 'author/tags/page',
     pages         => $pagination->pages_in_set,
     tags          => \@tags 
    }, 
    { layout => 'admin' };  }
  else {

    try {
      my $tag = resultset('Tag')->create({
        name   => $name,
        slug   => $slug
      });
    }
    catch {
      info "Could not create tag named '$name'";
    };

    template 'admin/tags/list',
    {
     success       => 'The tag was added successfully',
     all           => $all, 
     page          => 1,
     next_link     => $next_link,
     previous_link => $previous_link,
     action_url    => 'author/tags/page',
     pages         => $pagination->pages_in_set,
     tags          => \@tags 
    }, 
    { layout => 'admin' };
  }

};

=head2 /author/tags/delete/:id

Delete method

=cut

get '/author/tags/delete/:id' => sub {

  my $tag_id   = params->{id};
  my $tag      = resultset('Tag')->find( $tag_id );
  my $res_user = resultset('Users')->find_by_session(session);
  unless ( $res_user and $res_user->can_do( 'delete tag' ) ) {
    warn "***** Redirecting guest away from /author/tags/delete/:id";
    info "You are not allowed to delete tags, please create an account";
    redirect '/author/tags';
  }

  # Delete first all many to many dependecies for safly removal of the isolated tag
  my $check    = $tag->tag_creator;
  if ($check eq $res_user->username){
  try {
    foreach ( $tag->post_tags ) {
      $_->delete;
    }

    $tag->delete;
  }
  catch {
    info $_;
    error "Could not delete tag";
  };
 }
  redirect request->referer;

};

=head2 /author/tags/edit/:id

edit method

=cut

any '/author/tags/edit/:id' => sub {

  my $tag_id = params->{id};
  my $user   = resultset('Users')->find_by_session(session);
  my $nr_of_rows = 5;
  my $tag    = resultset('Tag')->find( $tag_id );

  my $name = params->{name};
  my $slug = string_to_slug( params->{slug} );
 
  my @aux_tags    = resultset('Tag')->user_tags($user->id);
  my $all         = scalar (@aux_tags);
  my @sorted_tags = sort {$b->id <=> $a->id} @aux_tags;
  my @tags        = splice(@sorted_tags,0*$nr_of_rows,$nr_of_rows);

  my $total_pages                 = get_total_pages($all, $nr_of_rows);
  my ($previous_link, $next_link) = get_previous_next_link(1, $total_pages, '/author/tags');
  
  my $total_posts     = $all;
  my $posts_per_page  = $nr_of_rows;
  my $current_page    = 1;
  my $pages_per_set   = 5;
  my $pagination      = generate_pagination_numbering($total_posts, $posts_per_page, $current_page, $pages_per_set);

  # Check if the form was submited
  if ( $name && $slug ) {
    my $found_slug = resultset('Tag')->search({ id => { '!=' => $tag->id }, slug => $slug })->first;
    my $found_name = resultset('Tag')->search({ id => { '!=' => $tag->id }, name => $name })->first;

    # Check if the user entered an existing slug
    if ( $found_slug ) {

    template 'admin/tags/list',
    {
     warning       => 'The slug already exists',
     all           => $all, 
     page          => 1,
     next_link     => $next_link,
     previous_link => $previous_link,
     action_url    => 'author/tags/page',
     pages         => $pagination->pages_in_set,
     tags          => \@tags 
    }, 
    { layout => 'admin' };

    }
    # Check if the user entered an existing name
    elsif ( $found_name ) {

    template 'admin/tags/list',
    {
     warning       => 'The name already exists',
     all           => $all, 
     page          => 1,
     next_link     => $next_link,
     previous_link => $previous_link,
     action_url    => 'author/tags/page',
     pages         => $pagination->pages_in_set,
     tags          => \@tags 
    }, 
    { layout => 'admin' };
    }
    else {
      my $check        = $tag->tag_creator;
      if ($check eq $user->username){
        try {
          $tag->update({
            name => $name,
            slug => $slug
          });
        }
        catch {
          info $_;
          error "Could not update tag named '$name'";
        };

      my @aux_tags    = resultset('Tag')->user_tags($user->id);
      my $all         = scalar (@aux_tags);
      my @sorted_tags = sort {$b->id <=> $a->id} @aux_tags;
      my @tags        = splice(@sorted_tags,0*$nr_of_rows,$nr_of_rows);

      template 'admin/tags/list',
      {
       success       => 'The slug was updated successfully',
       all           => $all, 
       page          => 1,
       next_link     => $next_link,
       previous_link => $previous_link,
       action_url    => 'author/tags/page',
       pages         => $pagination->pages_in_set,
       tags          => \@tags 
      }, 
      { layout => 'admin' };
      }
      else {
      template 'admin/tags/list',
      {
       warning       => 'You can modify only your tags!',
       all           => $all, 
       page          => 1,
       next_link     => $next_link,
       previous_link => $previous_link,
       action_url    => 'author/tags/page',
       pages         => $pagination->pages_in_set,
       tags          => \@tags 
      }, 
      { layout => 'admin' };
    }
    }
  }
  else {
    # If the form wasn't submited just list the tags
    template 'admin/tags/list',
      {
      tag  => $tag,
      tags => \@tags
      },
      { layout => 'admin' };
  }

};

1;
