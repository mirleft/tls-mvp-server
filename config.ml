open Mirage

let data_dir = "data"

let disk  = direct_kv_ro data_dir

let net =
  try match Sys.getenv "NET" with
    | "direct" -> `Direct
    | "socket" -> `Socket
  with Not_found -> `Socket


let stack console =
  match net with
    | `Direct -> direct_stackv4_with_default_ipv4 console tap0
    | `Socket -> socket_stackv4 console [Ipaddr.V4.any]

let server = foreign "Unikernel.Main" @@ console @-> stackv4 @-> kv_ro @-> job

let () =
  add_to_opam_packages [
    "mirage-clock-unix" ;
    "tls" ;
    "tcpip" ;
  ] ;
  add_to_ocamlfind_libraries [
    "mirage-clock-unix" ;
    "tls"; "tls.mirage";
    "tcpip.channel";
  ] ;
  register "tls-server" [ server $ default_console $ stack default_console $ disk ]
