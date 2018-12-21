{ pkgs }:

with pkgs.lib;

module:

let
  eval = evalModules {
    modules = [ module ] ++ [
      # To not have to import all NixOS modules...
      ../modules/fake.nix
      ../modules/system.nix
      ../modules/image.nix
      # This is to make nix optionnal
      ../modules/nix-daemon.nix
      ../modules/s6.nix
    ] ++ (map (m: (pkgs.path + "/nixos/modules/") + m) [
      "/system/etc/etc.nix"
      "/config/users-groups.nix"
      "/misc/assertions.nix"
      "/config/shells-environment.nix"
      "/config/system-path.nix"
      "/config/system-environment.nix"
      "/programs/environment.nix"
      "/misc/ids.nix"
      "/programs/bash/bash.nix"
      "/security/pam.nix"
      "/security/wrappers/default.nix"
      "/programs/shadow.nix"
      "/security/ca.nix"
      "/misc/meta.nix"
      "/misc/version.nix"
      "/services/continuous-integration/hydra/default.nix"
      "/services/databases/postgresql.nix"
      "/services/databases/postgresql.nix"
      "/services/web-servers/nginx/default.nix"
    ]);
    args = {
      inherit pkgs;
      utils = import (pkgs.path + /nixos/lib/utils.nix) pkgs;
    };
  };

  #  Activation user script is patched because it is creating
  # files in `/` while they have to be created in the build directory.
  activationScriptUsers = let
    userSpec = pkgs.lib.last (pkgs.lib.splitString " " eval.config.system.activationScripts.users.text);
    updateUsersGroupsPatched = pkgs.runCommand
      "update-users-groups-patched"
      { buildInputs = [ pkgs.gnused ]; }
      ''
        sed 's|/etc|etc|g;s|/var|var|g;s|nscd|true|g' ${(pkgs.path + /nixos/modules/config/update-users-groups.pl)} > $out
      '';
  in
    pkgs.runCommand "passwd-groups" { inherit userSpec; buildInputs = [ pkgs.jq ];} ''
      mkdir system
      cd system

      mkdir -p etc root $out

      # home dirs have to be created in the build directory
      sed 's|/home|home|g;s|/var|var|g' $userSpec > ../userSpecPatched

      ${pkgs.perl}/bin/perl -w \
        -I${pkgs.perlPackages.FileSlurp}/lib/perl5/site_perl \
        -I${pkgs.perlPackages.JSON}/lib/perl5/site_perl \
        ${updateUsersGroupsPatched} ../userSpecPatched

       cp -r * $out/
    '';

  containerBuilder =
    if eval.config.nix.enable
    then pkgs.dockerTools.buildImageWithNixDb
    else pkgs.dockerTools.buildImage;


  # This generates a script that run s6 locally
  # This is only used for debugging and test purpose
  standalone = pkgs.writeScript "s6-standalone" ''
    if [ $# -ne 1 ]
    then
     echo "Usage s6-standalone S6-SCANDIR"
     exit 1
    fi

    SCANDIR=$1

    if [ -e $SCANDIR ]
    then
      echo "S6-SCANDIR directory must not exist! Exiting."
      exit 2
    fi

    # Because S6 writes to the scan dir
    cp -Lr ${eval.config.system.build.etc}/etc/s6 $SCANDIR
    chmod u+w -R $SCANDIR

    # This is because s6 is run in an interactive shell
    # See the note section in https://skarnet.org/software/s6/s6-svscan.html
    for i in `ls $SCANDIR`; do touch $SCANDIR/$i/nosetsid; done

    # Do not use the generated finish since it kills all processes it can!
    echo "#!${pkgs.s6PortableUtils}/bin/s6-echo Terminated" > $SCANDIR/.s6-svscan/finish

    ${pkgs.s6}/bin/s6-svscan $SCANDIR
  '';


in containerBuilder {
  name = eval.config.image.name;
  tag = eval.config.image.tag;
  contents = [
    activationScriptUsers
    eval.config.system.path
    eval.config.system.build.etc ];
  extraCommands = eval.config.image.run;
  config = {
    # TODO: move to s6 module
    Cmd = [ "${pkgs.s6}/bin/s6-svscan" "/etc/s6" ];
    Env = mapAttrsToList (n: v: "${n}=${v}") eval.config.image.env;
  };
}
//
# For debugging purposes
{
  config = eval.config;
  s6Standalone = standalone;
}
