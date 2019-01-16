{ pkgs, lib, jq }:

with lib;

let
  image = lib.makeImage {
    config = {
      image = {
        name = "s6";
      };
      s6.services.stopContainer = {
        script = ''
          echo stopContainer
          exit 1
        '';
      };
    };
  };

in

lib.makeContainerTest {
  inherit image;
  testScript = ''
    $machine->waitForUnit("docker.service");
    $machine->succeed("docker load -i ${image}");
    $machine->succeed("docker run --name container -d ${lib.imageRef image}");
    $machine->waitUntilSucceeds("docker inspect container | ${jq}/bin/jq -e '.[].State.Status == \"exited\"'");
    $machine->succeed("docker logs container | grep -q stopContainer");
    $machine->succeed("docker logs container | grep -q 'sending all processes the TERM signal'");
  '';
}
