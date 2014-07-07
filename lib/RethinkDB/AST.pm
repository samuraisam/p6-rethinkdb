use RethinkDB::Connection;
use RethinkDB::Proto;
use RethinkDB::Exceptions;

my $term-type = RethinkDB::Proto::Term.TermType;

class X::RethinkDB::AST is X::RethinkDB {
    method message() {
        "AST Error: $.rc";
    }
}

class RQL::Query {
    has @.args;
    has %.optargs;
    has Int $.term-type   = Nil;
    has Str $.string-type = "undefined";

    method new(*@args, *%opts) {
        self.bless(:args(@args.map: &expr), :optargs(%opts));
    }

    method run(RethinkDB::Connection $c, *%global-optargs) {
        $c.start(:term(self), :%global-optargs);
    }

    method compose(@args, %optargs) {

    }

    method build() {
        my @res = $.term-type, @.args>>.build.item;
        if %.optargs.elems {
            @res.push %.optargs.pairs.map({ (.key => .value.build) }).hash;
        }
        @res;
    }
}

multi infix:<eqv>(RQL::Query $a, RQL::Query $b) is export {
    [&&] $a.term-type eq $b.term-type,
         $a.string-type eq $b.string-type,
         $a.args eqv $b.args,
         $a.optargs eqv $b.optargs;
}

class RQL::TopLevelQuery is RQL::Query {
    method compose(@args, %optargs) {
        @args <== %optargs.pairs.map({ [.key, '=', .value] });
        ['r.', $.string-type, '(', [@args], ')'];
    }
}

class RQL::DB is RQL::TopLevelQuery {
    has $.term-type = $term-type.DB;
    has $.string-type = 'db';
}

class RQL::Datum is RQL::Query {
    has $.data;

    method new($val) {
        self.bless(:data($val));
    }

    method build() {
        $.data;
    }

    method compose() {
        $.data.perl;
    }
}

sub expr($val, Int $nesting-depth = 20) {
    if $nesting-depth <= 0 {
        X::RethinkDB::AST.new("Nesting depth limit exceeded.").throw;
    }
    do given $val {
        when (RQL::Query) { $val }
        default           { RQL::Datum.new($val) }
    }
}
