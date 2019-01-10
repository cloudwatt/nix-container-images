self: super:

let
  lib = import ./lib { pkgs = super; };

  dockerImages = with lib; {
    nix = makeImage ./images/nix.nix;
    example = makeImage ./images/example.nix;
    example-systemd = makeImage ./images/example-systemd.nix;
  };

  tests = {
    s6 = super.callPackage ./tests/s6.nix { };
    readme = super.callPackage ./tests/readme.nix { };
    minimalImageSize = super.callPackage ./tests/minimal-image-size.nix { };
    dockerImages = {
      nix = super.callPackage ./tests/nix.nix { };
      from = super.callPackage ./tests/from.nix { };
      nginx = super.callPackage ./tests/nginx.nix { };
      env = super.callPackage ./tests/env.nix { };
      systemd = super.callPackage ./tests/systemd.nix { };
    };
  };
in
{
  inherit dockerImages tests;
  lib = super.lib // lib;
}

