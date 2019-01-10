# Systemd services are converted to s6 services. Be careful, the
# semantic of systemd service is not respected! See the README for
# details.

{ pkgs, config, lib, ...}:

# The systemd interface!
with import (pkgs.path + "/nixos/modules/system/boot/systemd-unit-options.nix") { inherit config lib; };

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
  systemdToS6 = name: service:
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
      type = let
        t = attrByPath ["serviceConfig" "Type"] "simple" service;
        in (if (t == "simple")
            then "long-run"
            else if (t == "oneshot" && isOneshotPost service)
                 then "oneshot-post"
                 else "oneshot-pre");
      script = let
        start = if hasAttrByPath ["serviceConfig" "ExecStart"] service
                then execStartToS6 service.serviceConfig.ExecStart
                else service.script;
        in attrByPath ["serviceConfig" "ExecStartPre"] "" service + "\n" + start;
    in
    {
      inherit type script;
      environment = service.environment;
      workingDirectory = attrByPath ["serviceConfig" "WorkingDirectory"] null service;
      # By default, it is false
      restartOnFailure = attrByPath ["serviceConfig" "Restart"] "no" service == "always";
      after = map (removeSuffix ".service") (attrByPath ["after"] [] service);
    };

  # TODO: print a warning on unsupported services
  supportedSystemdServices = let
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

  # If a oneshot service has a long run service in its after option,
  # this oneshot service is run after long run services.
  isOneshotPost = service: let
    type = attrByPath ["serviceConfig" "Type"] "simple";
    isLongRun = name: any (s: name == (s.name + ".service") && (type s) == "simple") (mapAttrsToList (name: v: v // { inherit name; }) supportedSystemdServices);
  in any isLongRun service.after;

 in

{
  options = {
    inherit systemd;
  };
  config.s6.services = mapAttrs systemdToS6 supportedSystemdServices;
}
