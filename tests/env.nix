{ pkgs, lib, curl }:

with lib;

let
  image = lib.makeImage {
    config = {
      image = {
        name = "env";
        env = {
          KEY = "value";
        };
      };
    };
  };

in

lib.makeContainerTest {
  inherit image;
  testScript = ''
    $machine->waitForUnit("docker.service");
    $machine->succeed("docker load -i ${image}");
    $machine->succeed("docker run ${lib.imageRef image} env | grep -q KEY=value");
  '';
}
