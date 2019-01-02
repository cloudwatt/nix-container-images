{ pkgs, lib, dockerImages }:

with lib;

lib.makeContainerTest {
  image = dockerImages.example-systemd;
  testScript = ''
    $machine->waitForUnit("docker.service");
    $machine->succeed("docker load -i ${dockerImages.example-systemd}");

    $machine->succeed("docker run --name systemd -d ${lib.imageRef dockerImages.example-systemd}");

    # Check the service second is started after the service first since second depend on first
    $machine->succeed("docker logs systemd | grep dependent services | sort --check");
  '';
}
