let
  nixpkgs = (import ../nix/sources.nix).nixpkgs;
  pkgs = import nixpkgs {
    overlays = [ (import ../overlay.nix) ];
  };
in
{
  inherit (pkgs) dockerImages;
  tests.nixContainerImages = pkgs.tests.nixContainerImages;
}
