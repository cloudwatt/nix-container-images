{ pkgs, lib, dockerTools }:

let
  image = lib.makeImage {
    config.image = {
      name = "from";
      from = dockerTools.pullImage {
        imageName = "alpine";
        imageDigest = "sha256:46e71df1e5191ab8b8034c5189e325258ec44ea739bba1e5645cff83c9048ff1";
        sha256 = "1xryr64b1s04l232ar5fk6gnlbikh8y1g3vg9g0kzwqyk36vxp81";
      };
    };
  };
in lib.makeContainerTest {
  inherit image;
  testScript = ''
    $machine->waitForUnit("docker.service");
    $machine->succeed("docker load -i ${image}");
  '';
}
