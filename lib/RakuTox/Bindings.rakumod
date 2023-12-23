unit module RakuTox::Bindings;
use NativeCall;
constant LIB = "toxcore";

enum Tox_Connection_Status is export (
    TOX_CONNECTION_NONE => 0,
    TOX_CONNECTION_TCP => 1,
    TOX_CONNECTION_UDP => 2
);

enum Tox_Err_New (
   TOX_ERR_NEW_OK => 0,
   TOX_ERR_NEW_NULL => 1,
   TOX_ERR_NEW_MALLOC => 2,
   TOX_ERR_NEW_PORT_ALLOC => 3,
   TOX_ERR_NEW_PROXY_BAD_TYPE => 4,
   TOX_ERR_NEW_PROXY_BAD_HOST => 5,
   TOX_ERR_NEW_PROXY_BAD_PORT => 6,
   TOX_ERR_NEW_PROXY_NOT_FOUND => 7,
   TOX_ERR_NEW_LOAD_ENCRYPTED => 8,
   TOX_ERR_NEW_LOAD_BAD_FORMAT => 9
);

enum Tox_err_Bootstrap (
    TOX_ERR_BOOTSTRAP_OK => 0
);

class CTox is repr('CPointer') {
}

class Tox_Options is repr('CStruct') is export {
    has bool $.udp_enabled = True;
}

sub tox_new(Pointer[Tox_Options]                   $options
           ,Pointer[int32]                $error
            ) is native(LIB) returns Pointer[CTox] { * }
sub tox_kill(Pointer[CTox] $tox) is native(LIB) { * }
sub tox_bootstrap(Pointer[CTox], Str $host, uint16 $port, Pointer[uint8] $public_key, Pointer[int32] $error) is native(LIB) { * }
sub tox_self_set_name(Pointer[CTox], Str $name is encoded('utf8'), uint16 $length, Pointer[int32] $error) is native(LIB) { * }
sub tox_self_get_name(Pointer[CTox], CArray[uint8] $name is rw) is native(LIB) { * }
sub tox_self_get_name_size(Pointer[CTox] --> size_t) is native(LIB) { * }
sub tox_self_set_status_message(Pointer[CTox], Str $status is encoded('utf8'), uint16 $length, Pointer[int32] $error) is native(LIB) { * }
sub tox_self_get_status_message(Pointer[CTox], CArray[uint8] $status is rw) is native(LIB) { * }
sub tox_self_get_status_message_size(Pointer[CTox] --> size_t) is native(LIB) { * }
sub tox_self_get_connection_status(Pointer[CTox], int32 $status is rw, Pointer $user_data is rw) is native(LIB) { * }
sub tox_version_major() is native(LIB) returns uint32 { * }
sub tox_version_minor() is native(LIB) returns uint32 { * }
sub tox_version_patch() is native(LIB) returns uint32 { * }

class Tox_PublicKey is export {
    has Str $!hex_key is built;
    has Blob[uint16] $!hex_bin is built;

    multi method from(::?CLASS:U $klass: Str $hex_key) {
        my $source_blob = $hex_key.encode("ascii");

        my @hex_blob = (0,2 ... $source_blob.list.elems - 1).map({ $source_blob.read-uint16($_) });
        my $hex_bin = blob16.new(@hex_blob);

        $klass.new(hex_key => $hex_key, hex_bin => $hex_bin)
    }

    method is-same-raw(List $raw) {
        $!hex_bin.list eqv $raw;
    }

    method as-pointer {
        nativecast(Pointer, $!hex_bin);
    }
}

class Tox is export {
    has Pointer[CTox] $.ctox is built;

    method new() {
        my Pointer[Tox_Options] $opts .= new();
        my Pointer[int32] $err .= new();
        my Pointer[CTox] $ctox = tox_new($opts, $err);
        
        $err == TOX_ERR_NEW_OK or die "fails creation of tox";
        
        return self.bless(:$ctox);
    }

    multi method version-major(Tox:U: --> Int) {
        return tox_version_major();
    }
    multi method version-minor(Tox:U: --> Int) {
        return tox_version_minor();
    }
    multi method version-patch(Tox:U: --> Int) {
        return tox_version_patch();
    }

    method bootstrap(Str $host, Int $port, Tox_PublicKey $public_key) {
        my Pointer[int32] $err .= new();

        tox_bootstrap($!ctox, $host, $port, $public_key.as-pointer, $err);

        $err == TOX_ERR_BOOTSTRAP_OK or die "fails bootstrap $host:$port";
    }

    method name {
        my $out = CArray[uint8].allocate(tox_self_get_name_size($!ctox));
        tox_self_get_name($!ctox, $out);
        return Buf.new($out.list).decode('utf8');
    }

    method set_name(Str $name) {
        my Pointer[int32] $err .= new();

        tox_self_set_name($!ctox, $name, $name.chars, $err);

        $err == 0 or die "fails to set name $name";
    }

    method set_status_message(Str $status) {
        my Pointer[int32] $err .= new();

        tox_self_set_status_message($!ctox, $status, $status.chars, $err);

        $err == 0 or die "fails to set status message $status";
    }

    method status_message {
        my $out = CArray[uint8].allocate(tox_self_get_status_message_size($!ctox));
        tox_self_get_status_message($!ctox, $out);
        return Buf.new($out.list).decode('utf8');
    }

    method connection_status {
        my int32 $out .= new;
        my Pointer $user_data .= new;

        tox_self_get_connection_status($!ctox, $out, $user_data);

        Tox_Connection_Status($out)
    }

    submethod DESTROY {
        tox_kill($!ctox);
    }
}
