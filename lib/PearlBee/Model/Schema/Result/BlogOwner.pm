use utf8;
package PearlBee::Model::Schema::Result::BlogOwner;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PearlBee::Model::Schema::Result::BlogOwner

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<blog_owners>

=cut

__PACKAGE__->table("blog_owners");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_admin

  data_type: 'boolean'
  is_nullable: 0

=head2 blog_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_date

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 status

  data_type: 'enum'
  default_value: 'inactive'
  extra: {custom_type_name => "active_state",list => ["inactive","active","suspended","pending"]}
  is_nullable: 0

=head2 activation_key

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_admin",
  { data_type => "boolean", is_nullable => 0 },
  "blog_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_date",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "status",
  {
    data_type => "enum",
    default_value => "inactive",
    extra => {
      custom_type_name => "active_state",
      list => ["inactive", "active", "suspended", "pending"],
    },
    is_nullable => 0,
  },
  "activation_key",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</blog_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id", "blog_id");

=head1 RELATIONS

=head2 blog

Type: belongs_to

Related object: L<PearlBee::Model::Schema::Result::Blog>

=cut

__PACKAGE__->belongs_to(
  "blog",
  "PearlBee::Model::Schema::Result::Blog",
  { id => "blog_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);





# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-07-21 08:46:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6bZn+8mJURbfScksRYJ9CQ
=head2 user

Type: belongs_to

Related object: L<PearlBee::Model::Schema::Result::User>

=cut
__PACKAGE__->belongs_to(
  "u",
  "PearlBee::Model::Schema::Result::Users",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub as_hashref {
  my ($self)   = @_;
  my $blog_owner_obj = {
    blog_id        => $self->blog_id,
    user_id        => $self->user_id,
    is_admin       => $self->is_admin,
    created_date   => $self->created_date,
    activation_key => $self->activation_key,
    status         => $self->status,
    blog_info      => $self->blog_info,

  };

  return $blog_owner_obj;

}

sub blog_info {
  my ($self)       = @_;
  my $schema       = $self->result_source->schema;
  my $blog         = $schema->resultset('Blog')->search({
    id => $self->blog_id
  });

  return $blog;
}

1;
