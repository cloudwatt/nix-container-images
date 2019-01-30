{ pkgs, config, lib, ...}:

with import ./s6-lib.nix { inherit pkgs; };
with lib;

let
  cfg = config;

  # Sort oneshot services based on their dependencies.
  # FIXME: abort on cycles by checking .cycle attribute
  oneshotsSorted = oneshots: let
    t = toposort (a: b: elem a.name b.after ) oneshots;
  in t.result;

  toAttrs = mapAttrsToList (name: v: v // { inherit name; });
  filtered = filterAttrs (n: v: v.enable) cfg.s6.services;

  s6ServicesMakeInitArgs = let
    services = toAttrs filtered;
    oneshotPres = filter (v: v.type == "oneshot-pre") services;
    longRuns = filter (v: v.type == "long-run") services;
    oneshotPosts = filter (v: v.type == "oneshot-post") services;
  in {
    oneshotPres = (oneshotsSorted oneshotPres);
    oneshotPosts = (oneshotsSorted oneshotPosts);
    longRuns = longRuns;
  };

  entryPoint = s6InitWithStateDir (s6ServicesMakeInitArgs // { inPidNamespace = true; });

  s6ServiceConfig = { name, config, ...}:
    {
      config = mkMerge [
        (mkIf (config.script != "")
          { execStart = pkgs.writeScript "s6-script-${name}" ''
            #! ${pkgs.runtimeShell} -e
            ${config.script}
          ''; })
      ];
    };

  s6ServiceOptions = {
    enable = mkOption {
      default = true;
      type = types.bool;
      description = "Whether to enable the service";
    };
    execStart = mkOption {
      type = with types; either str package;
      default = "";
      description = "Command executed as the service's main process.";
    };
    script = mkOption {
      type = types.lines;
      default = "";
      description = "Shell commands executed as the service's main process.";
    };
    type = mkOption {
      default = "long-run";
      type = types.enum ["long-run" "oneshot-pre" "oneshot-post"];
      description = "Type of the s6 service (oneshot-pre, long-run or oneshot-post).";
    };
    restartOnFailure = mkOption {
      default = false;
      type = types.bool;
      description = "Restart the service if it fails. Note this is only used by long-run services.";
    };
    workingDirectory = mkOption {
      default = null;
      type = types.nullOr types.str;
      description = "Sets the working directory for executed processes.";
    };
    user = mkOption {
      default = "root";
      type = types.str;
      description = "Set the UNIX user that the processes are executed as.";
    };
    environment = mkOption {
      default = {};
      type = with types; attrsOf (nullOr (either str (either path package)));
      example = { PATH = "/foo/bar/bin"; LANG = "nl_NL.UTF-8"; };
      description = "Environment variables passed to the service's processes.";
    };
    after = mkOption {
      default = [];
      type = types.listOf types.str;
      description = "Configure ordering dependencies between units.";
    };
    execLogger = mkOption {
      default = null;
      type = with types; nullOr (either str package);
      description = "Command executed as the service's logger: it gets the stdout of the main process.";
    };
  };

 in

{
  options = {
    s6.init = mkOption {
      type = types.nullOr types.package;
      default = null;
    };

    s6.services = mkOption {
      default = {};
      type = with types; attrsOf (submodule [{ options = s6ServiceOptions; } s6ServiceConfig ]);
      description = "Definition of s6 service.";
    };
  };

  # The s6 image entry point is only set if some services are defined
  config = mkIf (cfg.s6.services != {}) {
    s6.init = s6Init s6ServicesMakeInitArgs;
    image.entryPoint = [ "${entryPoint}" ];
  };
}
