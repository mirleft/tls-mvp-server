
open Lwt
open V1_LWT

let cs_of_lines strs =
  strs |> String.concat "\r\n"
       |> Cstruct.of_string

let resp meat =
  cs_of_lines [
    "HTTP/1.1 200 OK";
    "Connection: Close";
    "Content-type: text/plain";
    "";
    meat
  ]

module Main (C  : CONSOLE)
            (S  : STACKV4)
            (KV : KV_RO) =
struct

  module TCP  = S.TCPV4
  module TLS  = Tls_mirage.Make (TCP)
  module X509 = Tls_mirage.X509 (KV) (Clock)

  let reply c tls =
    TLS.write tls @@ resp "## We get signal."

  let upgrade c conf tcp =
    TLS.server_of_flow conf tcp >>= function
      | `Error _ ->
          C.log_s c "- upgrade error" >> TCP.close tcp
      | `Eof ->
          C.log_s c "- end of file while upgrading" >> TCP.close tcp
      | `Ok tls  ->
          C.log_s c "+ upgrade ok" >>
          reply c tls >> TLS.close tls >>
          C.log_s c ". reply sent"

  let port = try int_of_string Sys.argv.(1) with _ -> 4433
  let cert = try `Name Sys.argv.(2) with _ -> `Default

  let start c stack kv =
    lwt cert = X509.certificate kv cert in
    let conf = Tls.Config.server ~certificates:(`Single cert) () in
    S.listen_tcpv4 stack port (upgrade c conf) ;
    S.listen stack

end
