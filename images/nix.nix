{ pkgs, config, ...}:

{
  imports = [ ];
  config = {
    image = {
      name = "nix";
      run = ''
        chmod u+w root
        echo 'https://nixos.org/channels/19.03 nixpkgs' > root/.nix-channels
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
