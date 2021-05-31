{ lib, config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ffmpeg-full
    mkvtoolnix
    youtube-dl
    handbrake

    dos2unix
    vtt2srt # VTT to SRT converter
  ];

  nixpkgs.overlays = [
    (self: super: {
      # go vtt2srt script
      vtt2srt = super.callPackage ../../pkgs/vtt2srt {}; 
    })
  ];
}
