use RethinkDB::Proto;
use RethinkDB::Exceptions;
use RethinkDB::Query;

my $query-type = RethinkDB::Proto::Query.QueryType;

class RethinkDB::Connection;

has Int $.proto-version = RethinkDB::Proto::VersionDummy.Version.V0_3;
has Int $.proto-type    = RethinkDB::Proto::VersionDummy.Protocol.JSON;
has Int $!counter       = 0;
has Str $.host          = 'localhost';
has Int $.port          = 28015;
has Int $.timeout is rw = 30;
has Str $.db is rw;
has Bool $!is-connected = False;
has IO::Socket::INET $!connection;

class X::RethinkDB::Connection is X::RethinkDB {
  method message {
    "Connection error: '$.rc'";
  }
}

#= Write a 32-bit (wire type 5) value into a buffer at a given offset, updating the offset
sub write-fixed32(buf8 $buffer, Int $offset is rw, int $value) {
    my $buf := nqp::decont($buffer);
    nqp::bindpos_i($buf, $offset++, $value +& 255);
    nqp::bindpos_i($buf, $offset++, $value +> 8 +& 255);
    nqp::bindpos_i($buf, $offset++, $value +> 16 +& 255);
    nqp::bindpos_i($buf, $offset++, $value +> 24 +& 255);
}

#= Write a 64-bit (wire type 1) value into a buffer at a given offset, updating the offset
sub write-fixed64(buf8 $buffer, Int $offset is rw, int $value) {
    my $buf := nqp::decont($buffer);
    nqp::bindpos_i($buf, $offset++, $value +& 255);
    nqp::bindpos_i($buf, $offset++, $value +> 8 +& 255);
    nqp::bindpos_i($buf, $offset++, $value +> 16 +& 255);
    nqp::bindpos_i($buf, $offset++, $value +> 24 +& 255);
    nqp::bindpos_i($buf, $offset++, $value +> 32 +& 255);
    nqp::bindpos_i($buf, $offset++, $value +> 40 +& 255);
    nqp::bindpos_i($buf, $offset++, $value +> 48 +& 255);
    nqp::bindpos_i($buf, $offset++, $value +> 56 +& 255);
}

#= Write a utf8 into a buffer at a given offset, updating the offset
sub write-utf8(buf8 $buffer, Int $offset is rw, utf8 $blob8) {
    my $buf := nqp::decont($buffer);
    my $blob := nqp::decont($blob8);
    my int $buflen = nqp::elems($buf);
    my int $bloblen = nqp::elems($blob);

    nqp::setelems($buf, $offset + $bloblen)
           if $buflen < $offset + $bloblen;

    my int $s = 0;
    my int $d = $offset;
    while $s < $bloblen {
        nqp::bindpos_i($buf, $d, nqp::atpos_i($blob, $s));
        $s = $s + 1;
        $d = $d + 1;
    }

    $offset = $d;
}

#= Read a 32-bit (wire type 5) value from a buffer at a given offset, updating the offset
sub read-fixed32(blob8 $buffer, Int $offset is rw --> uint32) is export {
      $buffer[$offset++]
    + $buffer[$offset++] +< 8
    + $buffer[$offset++] +< 16
    + $buffer[$offset++] +< 24
}

#= Read a 64-bit (wire type 1) value from a buffer at a given offset, updating the offset
sub read-fixed64(blob8 $buffer, Int $offset is rw --> uint64) is export {
      $buffer[$offset++]
    + $buffer[$offset++] +< 8
    + $buffer[$offset++] +< 16
    + $buffer[$offset++] +< 24
    + $buffer[$offset++] +< 32
    + $buffer[$offset++] +< 40
    + $buffer[$offset++] +< 48
    + $buffer[$offset++] +< 56
}

#= Read a blob8 from a buffer at a given offset with a given length, updating the offset
sub read-utf8(blob8 $buffer, Int $offset is rw, Int $length --> utf8) is export {
    my $blob := $buffer.subbuf($offset, $length);
    $offset += min($length, $blob.elems);
    utf8.new($blob);
}

method connect() {
  if $!is-connected {
    X::RethinkDB::Connection.new(:rc('Already connected.')).throw;
  }
  $!connection = IO::Socket::INET.new(:host($.host), :port($.port), :timeout($.timeout));

  # RethinkDB Handshake Protocol:
  #
  # Perl                                 RethinkDB
  # ----------------------------------------------
  # i want v3        0x5f75e83e      =>
  # can haz auth?    $length || 0    =>
  # auth key if so   $authkey        =>
  # lets talk json   0x7e6970c7      =>
  #                                  <= null terminated string, "SUCCESS"

  my $buf = buf8.new(12);
  my $offset = 0;
  write-fixed32($buf, $offset, $.proto-version);
  write-fixed32($buf, $offset, 0);
  write-fixed32($buf, $offset, $.proto-type);
  $!connection.write($buf);

  my $resp = $!connection.recv().chop(1); # get rid of the null byte
  X::RethinkDB::Connection.new(:rc($resp)).throw if $resp ne 'SUCCESS';
  $!is-connected = True;
}

method next-counter() {
    $!counter++;
}

method is-connected() {
  $!is-connected;
}

method use($db) {
  $.db = $db;
}

method start(:$term, *%opts) {
  if !$!is-connected {
    X::RethinkDB::Connection.new(:rc('Not connected')).throw;
  }
  my $query := RethinkDB::Query.new(:type($query-type.START),
                                    :token($.next-counter), :$term, :%opts);
  warn "QUERY: {$query.json}";
  my $resp = $.send-query(:$query, :%opts);
  warn "QRESP: {$resp}";
  $resp;
}

method send-query(:$query, :%opts?) {
    my $utf8 = $query.json.encode('utf8');
    my $buf = buf8.new(12+$utf8.bytes);
    my $offset = 0;
    write-fixed64($buf, $offset, $query.token);
    write-fixed32($buf, $offset, $utf8.bytes);
    write-utf8($buf, $offset, $utf8);
    warn "WRITE {$!connection.write($buf)}";

    my $resp = $.read-response(:token($query.token));
    warn "SRESP: {$resp}";
    $resp;
}

method read-response(Int :$token) {
    warn "READING";
    my $rbuf = $!connection.recv(:bin);
    warn "FUCK $rbuf";
    my $offset = 0;
    my $rtoken = read-fixed64($rbuf, $offset);
    my $rlen = read-fixed32($rbuf, $offset);
    #my $rbytes = $!connection.read($rlen);
    my $rutf8 = read-utf8($rbuf, $offset, $rlen);

    my $resp = RethinkDB::Response.new($rtoken, $rutf8);
    if $resp.token != $token {
        X::RethinkDB::Connection.new(
          "Unexpected response received. Expected $token and got {$resp.token}"
        ).throw;
    }
    warn "RESP: {$resp}";
    $resp;
}
