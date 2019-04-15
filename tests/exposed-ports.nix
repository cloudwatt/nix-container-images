{ pkgs, lib, dockerTools, coreutils }:

let
  image = lib.makeImage {
    config = {
      image = {
        name = "exposed-ports";
        exposedPorts = { "5000/tcp" = {}; };
      };
      environment.systemPackages = [ coreutils ];
    };
  };
in lib.makeContainerTest {
  inherit image;
  testScript = ''
    $machine->waitForUnit("docker.service");
    $machine->succeed("docker load -i ${image}");
    $machine->succeed("docker run -d -P --name exposed-ports ${lib.imageRef image} sleep 10m");
    $machine->succeed("docker port exposed-ports | grep '5000/tcp -> 0.0.0.0'");
  '';
}
