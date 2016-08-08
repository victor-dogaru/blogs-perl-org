package  PearlBee::Model::Schema::ResultSet::Tag;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';
use PearlBee::Helpers::Util qw( string_to_slug );

=head2 search_lc

Search for a tag case-insensitive

=cut

sub search_lc {
  my ($self, $tag) = @_;
  my $schema = $self->result_source->schema;
  my $lc_tag = lc $tag; 
  return $schema->resultset('Tag')->
                  search( \[ "lower(name) like '\%$lc_tag\%'" ] );
}

=head2 find_or_create_with_slug

 Find or create tag with internally-generated slug

=cut

sub find_or_create_with_slug {
  my ($self, $args) = @_;
  my $schema = $self->result_source->schema;
  my $slug   = string_to_slug( $args->{name} );
  $slug      = $args->{slug} if $args->{slug} and $args->{slug} ne '';

  return $schema->resultset('Tag')->find_or_create({
    name => $args->{name},
    slug => $slug,
  });
}

=head2 create_with_slug

Create tag with internally-generated slug

=cut

sub create_with_slug {
  my ($self, $args) = @_;
  my $schema = $self->result_source->schema;
  my $slug   = string_to_slug( $args->{description} );
  $slug      = $args->{slug} if $args->{slug} and $args->{slug} ne '';

  $schema->resultset('Tag')->create({
    name => $args->{name},
    slug => $slug,
  });
}

sub user_tags {
  my ($self, $user_id) = @_;
  my $schema           = $self->result_source->schema;
  my @blog_owners      = $schema->resultset('BlogOwner')->search({ 
                          user_id => $user_id 
                          });
  my @blog_posts;
  my @tags;
  my @aux_tags;
  my @post_tags;
  for my $blog_owner ( @blog_owners ) {
  my @blog_posts_temp= $schema->
                   resultset('BlogPost')->search({ blog_id => $blog_owner->blog_id });
  $_->{blog_role}    = $blog_owner->is_admin for @blog_posts_temp;
  push @blog_posts, @blog_posts_temp; 
  }

  for my $blog (@blog_posts){
    my @post_tags_temp= $schema->
                     resultset('PostTag')->search({ post_id => $blog->post_id });
    $_->{blog_role}    = $blog->{blog_role} for @post_tags_temp;
    push @post_tags, @post_tags_temp;
  }

  for my $tag (@post_tags){
    my @aux_tags_temp = $schema->
                     resultset('Tag')->search({ id => $tag->tag_id});
    $_->{blog_role}    = $tag->{blog_role} for @aux_tags_temp;
    push @aux_tags, @aux_tags_temp;                    
  } 
  return @aux_tags;
}

1;
