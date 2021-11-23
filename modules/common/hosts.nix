{ lib }:
# TODO use this
let
  genAddress = number: "10.10.0.${toString number}/32";
  hosts = {
    akesi = {
      publicKey = "D7GuVBDF77tp369G5Mcvo8MBmHOvUAEGN6Ii3XgqXnc=";
      addresses = [ (genAddress 1) ];
      type = "server";
    };
    sona = {
      publicKey = "UYjsvFMCc+yRBPxX4rHiuRx1jQd1WntClaAueNXNmh4=";
      addresses = [ (genAddress 2) ];
      type = "client";
    };
  };
in
{
  getHost = host: hosts."${host}";
  getClients = lib.filterAttrs (n: v: v.type == "client") hosts;
}
