package Thrift::IDL::Struct;

=head1 NAME

Thrift::IDL::Struct

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Definition>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Definition);
__PACKAGE__->mk_accessors(qw(name children));

=head1 METHODS

=head2 name

=head2 children

Scalar accessors

=head2 fields

Returns array ref of L<Thrift::IDL::Field> children

=head2 field_named ($name)

=head2 field_id ($id)

Returns object found in fields array with given key value

=cut

sub to_str {
    return $_[0]->name . ' ('
        . join (', ', map { '' . $_ } @{ $_[0]->fields })
        . ')';
}

sub fields {
    my $self = shift;
    $self->children_of_type('Thrift::IDL::Field');
}

sub field_named {
    my ($self, $name) = @_;
    $self->array_search($name, 'fields', 'name');
}

sub field_id {
    my ($self, $name) = @_;
    $self->array_search($name, 'fields', 'id');
}

=head2 setup

A struct has children of type L<Thrift::IDL::Field> and L<Thrift::IDL::Comment>. Walk through all these children and associate the comments with the fields that preceeded them (if perl style) or with the field following.

=cut

sub setup {
    my $self = shift;

    my (@fields, @comments, $last_field);
    foreach my $child (@{ $self->children }) {
        if ($child->isa('Thrift::IDL::Field')) {
            $child->{comments} = [ @comments ];
            push @fields, $child;
            $last_field = $child;
            @comments = ();
        }
        elsif ($child->isa('Thrift::IDL::Comment')) {
            # Perl-style comments are postfix to the previous element
            if ($child->style eq 'perl_single') {
                push @{ $last_field->{comments} }, $child;
            }
            else {
                push @comments, $child;
            }
        }
        else {
            die "Unrecognized child of ".ref($self)." (".ref($child)."\n";
        }
    }
    $self->children(\@fields);
}

1;
