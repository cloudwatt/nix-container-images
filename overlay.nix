self: super:

let
  lib = import ./lib { pkgs = super; };

  dockerImages = with lib; {
    nix = makeImage ./images/nix.nix;
    example = makeImage ./images/example.nix;
    example-systemd = makeImage ./images/example-systemd.nix;
  };

  tests.dockerImages.nix = super.callPackage ./tests/nix.nix { };
in
{
  inherit dockerImages tests;
  lib = super.lib // lib;
}

