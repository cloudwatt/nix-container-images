{ pkgs, lib, dockerImages }:

with lib;

lib.makeContainerTest {
  image = dockerImages.nix;
  testScript = ''
    $machine->waitForUnit("docker.service");
    $machine->succeed("docker load -i ${dockerImages.nix}");
    $machine->succeed("docker run ${lib.imageRef dockerImages.nix} nix --version");
  '';
}
