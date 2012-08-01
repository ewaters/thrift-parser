namespace perl SC

typedef i16 CustomerId

// This is Container ID
// @validate range 400-5000
typedef i16 ContainerId

// @validate regex {^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$}
typedef string IPAddress

// @validate regex '^[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12}$'x
typedef string ContainerUuid

// @validate length 2-50
// @role internal
typedef string ContainerName

enum ContainerOS {
    CentOS_5_x86_64
}
enum ContainerStack {
    PHP
}

// Defines a security role
// @validate    regex   /^(customer|internal)$/
typedef string Role

// List of Roles
typedef list<Role> Roles

/*
    An address
*/
struct Address {
    1: string street,
    2: string city,
    3: string state,
    4: string zip,
    5: optional list<string> phoneNumbers,
    6: optional bool is_home,
    7: optional Roles roles,
}

/*
    A comment
*/
struct nestedContainers {
    1: map< string, list< list< i32 > > > stringListListInt,
}

/*
    At least one of the arguments passed was invalid.

    @param message The text of the error
    @param argument The name of the argument that was invalid
*/
exception InvalidArguments {
    1: string message,
    2: string argument
}

/*
    @role customer
*/

service Shared {
    /*
        Favorite color
    */
    void favoriteColor (
        1: string id, # @optional
    ),
}

/*
    @role customer
*/

service Common extends Shared {
    /*
        Health check
    */
    i16 healthCheck (
        1: string id, # @optional
    ),
}

service Container extends Common {
    /*
        Create a Container
        @role  customer
    */
    ContainerId create (
        1: CustomerId customerId,
        2: ContainerId id,        # the id of the container @role internal @optional
        3: ContainerUuid uuid,    # the uuid of the container @role internal @optional
        4: IPAddress address,     # the address @role internal @optional
        5: ContainerName name,
        6: ContainerOS os,
        7: ContainerStack stack,
    ) throws (1: InvalidArguments ouch),
}

service Directory {
    /*
        Staff addresses
        @role customer
    */
    map<string, Address> staffAddresses (
        1: string name, # @optional
    ) throws (1: InvalidArguments ouch),

    /*
        varTest
        @role blah
    */
    void varTest (
        1: map< string, map < string, string > > nestedHash,
    ) throws (1: InvalidArguments ouch),
}
