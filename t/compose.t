use strict;
use warnings;
use Thrift; # for constants
use Test::More qw(no_plan);
use Test::Deep;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok('MyAPI::Client::ThriftAMQP');
};

my $client = MyAPI::Client::ThriftAMQP->new(
    ThriftIDL => $FindBin::Bin . '/thrift/compose.thrift',
    Testing   => 1,
);
isa_ok($client, 'MyAPI::Client::ThriftAMQP');

cmp_deeply(
    SC::CustomerId->compose(68),
    all(
        methods(
            value => 68,
        ),
        isa('SC::CustomerId'),
        isa('Thrift::Parser::Type::Number'),
        isa('Thrift::Parser::Type::i16'),
    ),
    'CustomerId compose deep test',
);

# i16

eval { SC::CustomerId->compose(1_000_000) };
print "# $@\n";
isa_ok($@, 'Thrift::Parser::InvalidTypedValue', 'Too large');

eval { SC::CustomerId->compose(undef) };
print "# $@\n";
isa_ok($@, 'Thrift::Parser::InvalidTypedValue', 'Undefined');

# enum

isa_ok(SC::ContainerOS->compose('CentOS_5_x86_64'), 'SC::ContainerOS');
isa_ok(SC::ContainerOS->compose('_0'), 'SC::ContainerOS');

eval { SC::ContainerOS->compose(undef) };
print "# $@\n";
isa_ok($@, 'Thrift::Parser::InvalidArgument', 'Undefined');

# list

my @staff_names = ( 'Eric Waters', 'Jason Hansen', 'Mike Place' );
my @other_names = ( 'Josh Hansen', 'Justin Scheurer' );

my %staff_ages  = (
    'Eric Waters' => 29,
    'Jason Hansen' => 30,
    'Mike Place' => 31,
);

my %staff_addresses = (
    'Eric Waters' => {
        street => '529 Center St',
        city => 'Salt Lake City',
        state => 'Utah',
        zip => '84103',
        phoneNumbers => [ '801-560-8238', '801-448-7294' ],
        is_home => 1,
    },
    'Mike Place' => {
        street => '6733 Emigration Canyon',
        city => 'Salt Lake City',
        state => 'Utah',
        zip => '84103',
    },
    'Jason Hansen' => {
        street => '328 West 200 South',
        city => 'Salt Lake City',
        state => 'Utah',
        zip => '84101',
    }
);

# list< string >
isa_ok(
    Thrift::Parser::Type::list->new({
        val_type => TType::STRING,
        value => [ map { Thrift::Parser::Type::string->compose($_) } @staff_names ],
    }),
    'Thrift::Parser::Type::list'
);
isa_ok(
    Thrift::Parser::Type::list->define('::string')->compose([ @staff_names ]),
    'Thrift::Parser::Type::list'
);

isa_ok(
    SC::Address->compose({
        street => '123 Anywhere',
        city   => 'Salt Lake City',
        state  => 'Utah',
        zip    => 84103,
        roles  => [ 'home', 'work' ],
    }),
    'SC::Address',
);

isa_ok(
    SC::Roles->compose([ 'internal', 'customer' ]),
    'Thrift::Parser::Type::list',
);

# list< list< string > >
my $list = Thrift::Parser::Type::list->define('::list' => [ '::string' ])->compose([ \@staff_names, \@other_names ]);
isa_ok($list, 'Thrift::Parser::Type::list');
is($list->size, 2, "list size");
is($list->index(0)->size, int(@staff_names), "list index 0 size");
is($list->index(1)->size, int(@other_names), "list index 1 size");

eval {
    Thrift::Parser::Type::list->define('::list' => [ '::string' ])->compose([
        Thrift::Parser::Type::list->define('::i32')->compose([ 1, 2, 3 ]),
        Thrift::Parser::Type::list->define('::string')->compose(\@other_names),
    ])
};
isa_ok($@, 'Thrift::Parser::InvalidArgument', "Failed list<list<string>> compose where parent list<>'s child isn't list<string>");

isa_ok(
    Thrift::Parser::Type::list->define('::string')->compose([ SC::IPAddress->compose('127.0.0.1') ]),
    'Thrift::Parser::Type::list',
    "Success on list<string> compose where child is SC::IPAddress (typedef string)"
);
eval {
    Thrift::Parser::Type::list->define('::string')->compose([ SC::CustomerId->compose(123) ]);
};
isa_ok($@, 'Thrift::Parser::InvalidArgument', "Failed list<string> compose where child is SC::CustomerId (i16)");

$list = Thrift::Parser::Type::list->define('::list' => [ '::string' ])->compose([
    Thrift::Parser::Type::list->define('::string')->compose(\@staff_names),
    Thrift::Parser::Type::list->define('::string')->compose(\@other_names),
]);
isa_ok($list, 'Thrift::Parser::Type::list');
is($list->size, 2, "list size");
is($list->index(0)->size, int(@staff_names), "list index 0 size");
is($list->index(1)->size, int(@other_names), "list index 1 size");
cmp_deeply($list->value_plain, [ \@staff_names, \@other_names ], "Plain value of list of list of strings");

# list< map<string, i16> >
$list = Thrift::Parser::Type::list->define('::map' =>  [ '::string', '::i16' ])->compose([ \%staff_ages ]);
isa_ok($list, 'Thrift::Parser::Type::list');
cmp_deeply($list->value_plain, [ \%staff_ages ], "Plain value of list of map of string to i16");

# simple request

my $request = SC::Directory::staffAddresses->compose_message_call(
    name => 'Eric Waters',
);
isa_ok($request, 'Thrift::Parser::Message');

# map<string, Address>

my $response = $request->compose_reply(\%staff_addresses);
isa_ok($response, 'Thrift::Parser::Message');

my $Address = SC::Address->compose($staff_addresses{'Eric Waters'});
isa_ok($Address, 'SC::Address', "Manual SC::Address creation");
ok($Address->named('is_home')->is_true, "Bool value");

$response = $request->compose_reply({
    'Eric Waters' => $Address,
});
isa_ok($response, 'Thrift::Parser::Message', "compose_reply() with pre-typed value");

$response = $request->compose_reply([
    Thrift::Parser::Type::string->compose('Eric Waters') => $Address,
]);
isa_ok($response, 'Thrift::Parser::Message', "compose_reply() with pre-typed key/value pairs");

$response = eval { $request->compose_reply({ 'Incomplete Entry' => { street => '1234 Anywhere St.' } }) };
print "# $@\n";
isa_ok($@, 'Thrift::Parser::InvalidArgument');

$response = eval { $request->compose_reply({ 'Excess Entry' => { %{ $staff_addresses{'Eric Waters'} }, country => 'USA' } }) };
print "# $@\n";
isa_ok($@, 'Thrift::Parser::InvalidArgument');

# map<string, map<string, string>>

$request = SC::Directory::varTest->compose_message_call(
    nestedHash => {
        'Eric Waters' => {
            born => '20-Sep-1979',
            weight => 145,
        },
    },
);
isa_ok($request, 'Thrift::Parser::Message');

$response = $request->compose_reply();
isa_ok($response, 'Thrift::Parser::Message', 'compose_reply() with void response');

# Map object method tests

my $nestedHash = $request->arguments->named('nestedHash');
isa_ok($nestedHash, 'Thrift::Parser::Type::map');

cmp_deeply([ $nestedHash->keys   ], [ methods(value => 'Eric Waters') ],  "Map keys()");
cmp_deeply([ $nestedHash->values ], [ isa('Thrift::Parser::Type::map') ], "Map values()");

my ($key, $value) = $nestedHash->each;
cmp_deeply([ $value->keys ], bag( methods(value => 'born'), methods(value => 'weight') ), "Map each()");

($key, $value) = $nestedHash->each;
is($key, undef, "Map each() exhausted");

($key, $value) = $nestedHash->each;
isa_ok($key, 'Thrift::Parser::Type::string', "Map each() reset");

eval { Thrift::Parser::Type::string->compose([ 'invalid', 'string' ]) };
print "# $@\n";
isa_ok($@, "Thrift::Parser::InvalidTypedValue");

# List object method tests

$list = Thrift::Parser::Type::list->define('::string')->compose([ @staff_names ]);
$value = $list->each;
is($value->value, 'Eric Waters', "List each (first)");
$value = $list->each;
$value = $list->each;
$value = $list->each;
is($value, undef, "List exhausted");

is($list->index(1)->value, 'Jason Hansen', "List index()");

# Set object method tests

my $set = Thrift::Parser::Type::set->define('::string')->compose([ @staff_names ]);

ok($set->is_set('Eric Waters'), "is_set() with untyped value");
ok($set->is_set( Thrift::Parser::Type::string->compose('Eric Waters') ), "is_set() with typed value");

$request = SC::Container::create->compose_message_call(
    customerId => SC::CustomerId->compose(500),
    id         => SC::ContainerId->compose(100),
    uuid       => SC::ContainerUuid->compose('blah-blah-blah'),
    address    => '127.0.0.1',
);
isa_ok($request, 'Thrift::Parser::Message');

# Extended service methods

$request = SC::Container::healthCheck->compose_message_call(
    id => '12345',
);
isa_ok($request, 'Thrift::Parser::Message');
is($request->method, 'SC::Container::healthCheck', "Request method is 'healthCheck' string");

$request = SC::Container::favoriteColor->compose_message_call(
    id => '12345',
);
isa_ok($request, 'Thrift::Parser::Message');

$list = SC::nestedContainers->compose({
    stringListListInt => {
        'Eric' => [ [ 10, 15 ], [ 20, 25 ] ],
    }
});
isa_ok($list, 'SC::nestedContainers');

#done_testing();

__DATA__
my $value = eval {

};
if (my $e = Thrift::Parser::Exception->caught()) {
    $e->show_trace(1);
    print $e->as_string . "\n";
}

print Dumper($value);
exit;

