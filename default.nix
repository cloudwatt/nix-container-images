{ pkgs ? import <nixpkgs> { } }:

let
  makeImage = pkgs.callPackage ./make-image.nix {};
in

{
  nix = makeImage ./images/nix.nix;
}
