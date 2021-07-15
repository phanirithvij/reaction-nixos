{ lib, config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # CLI
      ## network
        mtr # interactive trace route
      ## video
      ffmpeg-full
      mkvtoolnix
      youtube-dl
      handbrake

      ## text
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
