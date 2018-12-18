{ pkgs, dockerImages }:

with builtins;
with import (pkgs.path + /nixos/lib/testing.nix) { system = builtins.currentSystem; };

let
  # Takes the image derivation and returns the hash
  imageHash = image: head (split "-" (baseNameOf image));
  imageRef = image: "${image.imageName}:${imageHash image}";

  image = dockerImages.nix;

  machine = { config, ... }: {

    config = rec {
      virtualisation = {
        docker.enable = true;
        diskSize = 1024;
      };
    };
  };

  testScript = ''
    $machine->waitForUnit("docker.service");
    $machine->succeed("docker load -i ${image}");
    $machine->succeed("docker run ${imageRef image} nix --version");
  '';

in
  makeTest { name = image.imageName; nodes = { inherit machine; }; testScript = testScript; }
