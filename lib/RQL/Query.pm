need RethinkDB::Connection;

class RQL::Query {
    has @.args;
    has %.optargs;
    has Int $.term-type   = Nil;
    has Str $.string-type = "undefined";

    method new(*@args, *%opts) {
        self.bless(:args(@args.map: &expr), :optargs(%opts));
    }

    method run(RethinkDB::Connection $c, *%global-optargs) {
        $c.start(:term(self), :opts(%global-optargs));
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
