unit module RakuTox::Bindings;
use NativeCall;
constant LIB = "toxcore";

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

class CTox is repr('CPointer') {
}

class Tox_Options is repr('CStruct') is export {
    has bool $.ipv6_enabled;
}

sub tox_new(Pointer[Tox_Options]                   $options
           ,Pointer[int32]                $error
            ) is native(LIB) returns Pointer[CTox] { * }
sub tox_kill(Pointer[CTox] $tox) is native(LIB) { * }

class Tox is export {
    has Pointer[CTox] $!ctox;

    method new() {
        my Pointer[Tox_Options] $opts .= new();
        my Pointer[int32] $err .= new();
        my Pointer[CTox] $ctox = tox_new($opts, $err);
        
        $err != TOX_ERR_NEW_OK or die "fails creation of tox";
        
        return self.bless(:$ctox);
    }

    submethod DESTROY {
        tox_kill($!ctox);
    }
}
