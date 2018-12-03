{ pkgs ? import <nixpkgs> { } }:

let
  makeImage = pkgs.callPackage ./make-image.nix {};
in

{
  nix = makeImage ./containers/nix.nix;
}
