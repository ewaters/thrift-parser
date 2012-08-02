package Thrift::Parser::Test;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Test::Deep;
use Test::Exception;
use Thrift::Parser::TestCommon;

use Thrift::Parser;
use Thrift::IDL;

my ($idl, $parser);

sub create_idl : Test(startup) {

	$idl = Thrift::IDL->parse_thrift(<<"	ENDTHRIFT");
	namespace perl TPT

	typedef i32 number

	enum operation {
		Add, Subtract, Multiply, Divide
	}

	struct action {
		1: number num1,
		2: number num2,
		3: operation op
	}

	exception invalidArguments {
		1: string message,
		2: string argument
	}

	service Calculator {
		number compute (
			1: action action,
			2: string comment
		) throws (
			1: invalidArguments invalid
		)
	}
	ENDTHRIFT

	$parser = Thrift::Parser->new(
		idl     => $idl,
		service => 'Calculator',
	);
}	

sub class_resolution : Tests(1) {
	my $number_idl = $idl->typedef_named('number');
	is $parser->idl_type_class($number_idl), 'TPT::IDL::number', "idl_type_class() with custom type";
}

1;
