use RethinkDB::Exceptions;
use RethinkDB::Proto;
use RethinkDB::AST;
use JSON::Tiny;

my $query-type = RethinkDB::Proto::Query.QueryType;
my $response-type = RethinkDB::Proto::Response.ResponseType;

class RethinkDB::Query;

class X::RethinkDB::Query is X::RethinkDB {
    method message() {
        "Query error: '$.rc'}"
    }
}

has Int $.type;
has Int $.token;
has $.term;
has %.opts;

method new(Int :$type!, Int :$token!, :$term?, :%opts?) {
    self.bless(:$type, :$token, :$term, :opts(%opts // ().hash));
}

method json() {
    my @res = $.type;
    @res.push: $.term.build.item if $.term ~~ RQL::Query;
    @res.push: %.opts.item;
    return to-json(@res);
}
