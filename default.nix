{ nixpkgs ? builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/9ea650bb5de4b6965ca4e4efe539c3ea76ce1102.tar.gz
, pkgs ? import nixpkgs {}
}:

let
  makeImage = pkgs.callPackage ./make-image.nix {};

  dockerImages = {
    nix = makeImage ./images/nix.nix;
    example = makeImage ./images/example.nix;
    example-systemd = makeImage ./images/example-systemd.nix;
  };

  tests.nix = pkgs.callPackage ./tests/nix.nix { inherit dockerImages; };

in
{
  inherit makeImage dockerImages tests;
}

