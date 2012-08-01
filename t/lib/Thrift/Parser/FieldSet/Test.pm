package Thrift::Parser::FieldSet::Test;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Test::Exception;
use Thrift::Parser::TestCommon;

use Thrift::Parser;

my $class = 'Thrift::Parser::FieldSet';

sub field_new : Tests(4) {
	my $field = new_field
		id    => 42,
		name  => 'field_one',
		value => new_type string => "Hello world";

	isa_ok $field, 'Thrift::Parser::Field';
	is $field->id, 42, "id()";
	is $field->name, 'field_one', "name()";
	isa_ok $field->value, 'Thrift::Parser::Type::string', "value()";
}

sub fieldset_new : Tests(1) {
	my $set = $class->new({ fields => [
		new_field(
			id    => 0,
			name  => 'first_name',
			value => new_type string => 'Eric'
		),
		new_field(
			id    => 1,
			name  => 'last_name',
			value => new_type string => 'Waters'
		),
	] });
	isa_ok $set, $class, "Created field set";
}

1;
