{ pkgs, config, lib, ...}:

# The systemd interface!
with import (pkgs.path + "/nixos/modules/system/boot/systemd-unit-options.nix") { inherit config lib; };
with import ./s6-lib.nix { inherit pkgs; };

with lib;

let

  cfg = config;

  serviceConfig = { name, config, ... }: {
    config = mkMerge
      [ { # Default path for systemd services.  Should be quite minimal.
          # TODO: adapt that to s6  
          path =
            [ pkgs.coreutils
              pkgs.findutils
              pkgs.gnugrep
              pkgs.gnused
            ];
          environment.PATH = config.path;
        }
        (mkIf (config.preStart != "")
          { serviceConfig.ExecStartPre = config.preStart; })
        (mkIf (config.script != "")
          { serviceConfig.ExecStart = pkgs.writeScript "s6-${name}-script" config.script; })
      ];
  };

  systemd.services = mkOption {
      default = {};
      type = with types; attrsOf (submodule [ { options = serviceOptions; } serviceConfig ]);
      description = "Definition of systemd service units.";
  };

  systemd.packages = mkOption {
      type = "undefined";
  };

  systemd.sockets = mkOption {
      type = "undefined";
  };

  # Transform some systemd arguments to be used by s6
  systemdToS6 = service:
    let
      # execStart can start with special characters that needs to be
      # interpreted.
      # @/bin/service service arg1 -> exec -a service /bin/service arg1
      execStartToS6 = e:
        let l = splitString " " e;
        in if pkgs.lib.hasPrefix "@" (head l)
           then concatStringsSep " " ([
            "-a"
            (elemAt l 1)
            (pkgs.lib.removePrefix "@" (head l))
            ] ++ (drop 2 l))
          else e;
    in
    {
      name = service.name;
      environment = service.environment;
      execStart = execStartToS6 service.serviceConfig.ExecStart;
      execStartPre = attrByPath ["serviceConfig" "ExecStartPre"] "" service;
      type = attrByPath ["serviceConfig" "Type"] "" service;
      chdir = attrByPath ["serviceConfig" "WorkingDirectory"] "" service;
    };

  # Cron services are not supported
  # TODO: print a warning on unsupported services
  supportedServices = filterAttrs (n: v: v.startAt == [] || hasAttr "ExecStart" v) cfg.systemd.services;

  # Generate all files required per services
  etcS6 = let
    genS6File = { name, generator }:
      lib.mapAttrs'
        (n: v: nameValuePair "s6/${n}/${name}" { source = generator (systemdToS6 (v // {name = n;}));})
        supportedServices;
  in
    fold (a: b: genS6File a // b) {} [
      {name = "run"; generator = genS6Run; }
      {name = "finish"; generator = genS6Finish; }
      {name = "notification-fd"; generator = genS6NotificationFd; }];

 in

{
  options = { inherit systemd; };

  config = {
    # TODO: Do not add it in systemPackages
    environment.systemPackages = [ pkgs.execline ];
    environment.etc = etcS6;
  };
}
