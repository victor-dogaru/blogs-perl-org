use utf8;
package PearlBee::Model::Schema::Result::BlogPost;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PearlBee::Model::Schema::Result::BlogPost - Blog Postings.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 TABLE: C<blog_post>

=cut

__PACKAGE__->table("blog_post");

=head1 ACCESSORS

=head2 post_id

  data_type: 'integer'
  is_nullable: 0

=head2 blog_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_nullable => 0 },
  "blog_id",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</post_id>

=item * L</blog_id>

=back

=cut

__PACKAGE__->set_primary_key("post_id", "blog_id");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-23 12:42:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DVbLOOt1XlToZB7+hBeLDQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;