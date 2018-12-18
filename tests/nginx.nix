{ pkgs, lib, curl }:

with lib;

let
  wwwDir = pkgs.runCommand "wwwDir" {} ''
    mkdir $out
    echo plop > $out/plop
  '';

  image = lib.makeImage {
    config = {
      image = {
        name = "nginx";
      };
      services.nginx = {
        enable = true;
        virtualHosts.localhost.root = wwwDir;
      };
    };
  };

in

lib.makeContainerTest {
  inherit image;
  testScript = ''
    $machine->waitForUnit("docker.service");
    $machine->succeed("docker load -i ${image}");
    $machine->succeed("docker run -d -p 8000:80 ${lib.imageRef image}");
    $machine->waitUntilSucceeds("${curl}/bin/curl -f localhost:8000/plop");
  '';
}
