class RethinkDB::Connection;

has Int $.proto-version = 0x5f75e83e;
has Int $.proto-type    = 0x7e6970c7;
has Int $!counter       = 0;
has Str $.host          = 'localhost';
has Int $.port          = 28015;
has Int $.timeout is rw = 30;
has Str $.db is rw;
has Bool $!is-connected = False;
has IO::Socket::INET $!connection;

class X::RethinkDB is Exception {
  has $.rc;
}

class X::RethinkDB::Connection is X::RethinkDB {
  method message {
    "Connection error: '$.rc'";
  }
}

#= Write a 32-bit (wire type 5) value into a buffer at a given offset, updating the offset
sub write-fixed32(buf8 $buffer, Int $offset is rw, int $value) is export {
    my $buf := nqp::decont($buffer);
    nqp::bindpos_i($buf, $offset++, $value +& 255);
    nqp::bindpos_i($buf, $offset++, $value +> 8 +& 255);
    nqp::bindpos_i($buf, $offset++, $value +> 16 +& 255);
    nqp::bindpos_i($buf, $offset++, $value +> 24 +& 255);
}

#= Write a 64-bit (wire type 1) value into a buffer at a given offset, updating the offset
sub write-fixed64(buf8 $buffer, Int $offset is rw, int $value) is export {
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

method is-connected() {
  $!is-connected;
}

method use($db) {
  $.db = $db;
}

method send() {
  if !$!is-connected {
    X::RethinkDB::Connection.new(:rc('Not connected')).throw;
  }

}
