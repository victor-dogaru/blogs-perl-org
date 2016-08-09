package  PearlBee::Model::Schema::ResultSet::Category;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';
use PearlBee::Helpers::Util qw( string_to_slug );

=head2 create_with_slug

Create category with internally-generated slug

=cut

sub create_with_slug {
  my ($self, $args) = @_;
  my $schema = $self->result_source->schema;
  my $slug   = $args->{slug} || $args->{name};
  $slug      = string_to_slug( $slug );

  $schema->resultset('Category')->create({
    name    => $args->{name},
    slug    => $slug,
    user_id => $args->{user_id}
  });
}

=head2 find_or_create_with_slug

Find or create category with internally-generated slug

=cut

sub find_or_create_with_slug {
  my ($self, $args) = @_;
  my $schema = $self->result_source->schema;
  my $slug   = string_to_slug( $args->{name} );
  $slug      = $args->{slug} if $args->{slug} and $args->{slug} ne '';

  return $schema->resultset('Category')->find_or_create({
    name    => $args->{name},
    slug    => $slug,
    user_id => $args->{user_id}
  });
}

sub user_categories{

  my ($self, $user_id) = @_;
  my $schema           = $self->result_source->schema;
  my @blog_owners      = $schema->resultset('BlogOwner')->search({ 
                          user_id => $user_id 
                          });
  my @blog_posts;
  my @categories;
  my @post_categories;

  for my $blog_owner ( @blog_owners ) {
  my @tmp_blogs      = $schema->resultset('BlogPost')->
  search({ blog_id => $blog_owner->blog_id });
  $_->{blog_role}    = $blog_owner->is_admin for @tmp_blogs;
  push @blog_posts, @tmp_blogs;                   
  }

  for my $blog (@blog_posts){
  my @post_categories_temp = $schema->
                     resultset('PostCategory')->search({ post_id => $blog->post_id });
  $_->{blog_role}    = $blog->{blog_role} for @post_categories_temp;
  push @post_categories, @post_categories_temp; 
  }

  for my $category (@post_categories){
    my @categories_temp = $schema->
                     resultset('Category')->search({ name => { '!=' => 'Uncategorized'}, id => $category->category_id });
  $_->{blog_role}    = $category->{blog_role} for @categories_temp;
  push @categories, @categories_temp;                
  } 

  my @non_post_categories= $schema->resultset('Category')->search({user_id =>$user_id});
  my $seen = {};
  @categories = grep !$seen->{$_->id}++, (@categories, @non_post_categories);

  return @categories;
}

1;
