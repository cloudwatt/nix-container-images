{ nixpkgs ? (import nix/sources.nix).nixpkgs }:

let
  pkgs = import nixpkgs {
    overlays = [ (import ./overlay.nix) ];
  };

  docs = pkgs.callPackages ./docs {};
in
  pkgs //
  # We don't need to expose docs in the overlay
  { inherit docs; }
