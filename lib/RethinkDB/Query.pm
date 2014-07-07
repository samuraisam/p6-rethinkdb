use RethinkDB::Exceptions;
use RethinkDB::Proto;
use JSON::Tiny;

my $query-type = RethinkDB::Proto::Query.QueryType;
my $response-type = RethinkDB::Proto::Response.ResponseType;

class RethinkDB::Query;

class X::RethinkDB::Query is X::RethinkDB {
    method message() {
        "Query error: '$.rc'}"
    }
}

has Int $.type = Nil;
has $.token    = Nil;
has Int $.term = Nil;
has %.opts; # either string=>Query or just string=>string

method validate() {
    X::RethinkDB::Query.new(:rc("Type not defined for Query")).throw if $!type eq Nil;
}

method json() {
    .validate();
    my @res = $.type;
    return to-json(@res);
}
