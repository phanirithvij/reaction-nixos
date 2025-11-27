{ pkgs }:
{
  programs.bash.shellInit = ''
    [ -f ${pkgs.fzf}/share/fzf/completion.bash ] && source ${pkgs.fzf}/share/fzf/completion.bash
    [ -f ${pkgs.fzf}/share/fzf/key-bindings.bash ] && source ${pkgs.fzf}/share/fzf/key-bindings.bash
  '';
  programs.bash.shellInit =
    lib.concatMapStrings
      (
        file:
        let
          path = "${pkgs.fzf}/share/fzf/${file}";
        in
        "[ -f ${path} ] && source ${path}\n"
      )
      [
        "completion.bash"
        "key-bindings.bash"
      ];
  programs.bash.shellInit = lib.concatMapStrings (file: "[ -f ${path} ] && source ${path}\n") (
    map (file: "${pkgs.fzf}/share/fzf/${file}") [
      "completion.bash"
      "key-bindings.bash"
    ]
  );
}
