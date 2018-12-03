{ pkgs, config, ...}:

{
  imports = [ ];
  config = {
    nix.enable = true;

    image = {
      name = "nix";
    };
  };
}
