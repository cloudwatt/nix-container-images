{ pkgs, config, ...}:

let
  channel = builtins.replaceStrings ["\n"] [""]
    "nixos-${builtins.readFile "${pkgs.path}/.version"}";
in
{
  imports = [ ];
  config = {
    image = {
      name = "nix";
      run = ''
        chmod u+w root
        echo 'https://nixos.org/channels/${channel} nixpkgs' > root/.nix-channels
      '';
      interactive = true;
    };

    environment.systemPackages = [ pkgs.nix ];

    nix = {
      enable = true;
      useSandbox = false;
    };
  };
}
