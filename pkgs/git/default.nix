{ pkgs, ... }:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "amwo";
        email = "tsushimori@gmail.com";
      };

      init.defaultBranch = "main";

      pull = {
        rebase = true;
        ff = "only";
      };

      core = {
        editor = "nvim";
        autocrlf = "input";
      };

      merge.conflictstyle = "diff3";
    };
  };
}
