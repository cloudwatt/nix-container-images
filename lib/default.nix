{ pkgs }:

with builtins;
with import (pkgs.path + /nixos/lib/testing.nix) { system = builtins.currentSystem; };

rec {
  # Takes the image derivation and returns the hash
  imageHash = image: head (split "-" (baseNameOf image));
  imageRef = image: "${image.imageName}:${imageHash image}";

  makeImage = pkgs.callPackage ./make-image.nix {};

  # Build a test vm with Docker enable
  # It also exposes the `image` attribute.
  makeContainerTest = { image, testScript }:
    let
      machine = { config, ... }: {
        config = {
          virtualisation = {
            docker.enable = true;
            diskSize = 1024;
          };
        };
      };
    in
    makeTest {
      name = image.imageName;
      nodes = { inherit machine; };
      inherit testScript;
    } //
    { inherit image; };
}
