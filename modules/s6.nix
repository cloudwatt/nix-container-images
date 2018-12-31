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

  # Generate s6 arguments from systemd service definition
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
      type = attrByPath ["serviceConfig" "Type"] "simple" service;
      environment = service.environment;
      execStart = execStartToS6 service.serviceConfig.ExecStart;
      execStartPre = attrByPath ["serviceConfig" "ExecStartPre"] "" service;
      chdir = attrByPath ["serviceConfig" "WorkingDirectory"] "" service;
      restart = attrByPath ["serviceConfig" "Restart"] "no" service;
      after = attrByPath ["after"] [] service;
    };

  # TODO: print a warning on unsupported services
  supportedServices = let
    predicates = n: v: all (f: f n v) [
      # Units containing calendar event are not supported (cron jobs)
      (n: v: v.startAt == [])
      # Units have either ExecStart or a script
      (n: v: hasAttrByPath ["serviceConfig" "ExecStart"] v || (v.script != ""))
      # Only Restart values no and always are supported
      (n: v: (! hasAttrByPath ["serviceConfig" "Restart"] v) || (v.serviceConfig.Restart == "no") || (v.serviceConfig.Restart == "always"))
    ];
  in
   filterAttrs predicates cfg.systemd.services;

  # Partition oneshot and longrun services
  s6ServicesPartitions = partition (s: s.type == "oneshot") (mapAttrsToList (n: v: systemdToS6 ({name = n;} // v)) supportedServices);

  longRuns =  s6ServicesPartitions.wrong;
  oneshots = s6ServicesPartitions.right; 

  # Sort oneshot services based on their dependencies.
  # FIXME: abort on cycles by checking .cycle attribute
  oneshotsSorted = oneshots: let
    t = toposort (a: b: elem (a.name + ".service") b.after ) oneshots;
  in t.result;

  # If a oneshot service has a long run service in its after option,
  # this oneshot service is run after long run services.
  oneshotPostPre = let
    isLongRun = name: any (s: name == (s.name + ".service")) longRuns;
  in partition (o: any isLongRun o.after) oneshots;
  oneshotPre = oneshotPostPre.wrong;
  oneshotPost = oneshotPostPre.right;

 in

{
  options = {
    inherit systemd;
    s6.init = mkOption {
      type = types.nullOr types.package;
      default = null;
    };
  };

  # The s6 image entry point is only set if some services are defined
  config = mkIf ((oneshots != []) || (longRuns != [])) {
    s6.init = s6Init (oneshotsSorted oneshotPre) (oneshotsSorted oneshotPost) longRuns;
    image.entryPoint = [ "${s6InitWithStateDir (oneshotsSorted oneshotPre) (oneshotsSorted oneshotPost) longRuns}" ];
  };
}
