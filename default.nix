{ nixpkgs ? builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/9ea650bb5de4b6965ca4e4efe539c3ea76ce1102.tar.gz }:

import nixpkgs {
  overlays = [ (import ./overlay.nix) ];
}
