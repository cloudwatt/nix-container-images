{ pkgs, config, lib, ...}:

# The systemd interface!
with import (pkgs.path + "/nixos/modules/system/boot/systemd-unit-options.nix") { inherit config lib;};
with import ./s6-lib.nix { inherit pkgs; };

with lib;

let

  cfg = config;

  checkService = checkUnitConfig "Service" [
    (assertValueOneOf "Type" [
      "simple" "oneshot"
    ])
    (assertValueOneOf "Restart" [
      "no" "on-success" "on-failure" "on-abnormal" "on-abort" "always"
    ])
  ];

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
      type = with types; attrsOf (submodule [ { options = serviceOptions; } serviceConfig  ]);
      description = "Definition of systemd service units.";
  };

  systemd.packages = mkOption {
      type = "undefined";
  };

  systemd.sockets = mkOption {
      type = "undefined";
  };

  systemdToS6 = service:
    let
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

  removeUnsupportedUnits = filterAttrs (n: v: v.startAt == []);

  etcS6Run = lib.mapAttrs'
    (n: v: nameValuePair "s6/${n}/run" { source = genS6Run (systemdToS6 (v // {name = n;}));})
    (removeUnsupportedUnits cfg.systemd.services);

 in

{
  options = { inherit systemd; };

  config = {
    # TODO: Do not add it in systemPackages
    environment.systemPackages = [ pkgs.execline ];
    environment.etc = etcS6Run;
  };
}
