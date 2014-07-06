use RethinkDB::Proto;
use JSON::Tiny;

my $query-type = RethinkDB::Proto::Query.QueryType;
my $response-type = RethinkDB::Proto::Response.ResponseType;

class RethinkDB::Query;

has Int $!type;
has $!token;
has Int $!term = Nil;
has %!opts; # either string=>Query or just string=>string

method json() {
    my @res = $!type;
    return to-json(@res);
}
