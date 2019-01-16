# FIXME: This file should be moved to lib/ but I fail to make it
# available for the NixOS module system...

{ pkgs }:

with pkgs.lib;

let
  envDir = env: pkgs.runCommand "env-dir" {} (''
    mkdir $out
  '' + concatStringsSep "\n" (mapAttrsToList (n: v: "echo ${v} > $out/${n}") env));
  path = "${pkgs.execline}/bin:${pkgs.s6PortableUtils}/bin:${pkgs.s6}/bin:${pkgs.coreutils}/bin";

in rec {

  s6InitWithStateDir = args: pkgs.writeTextFile {
    name = "init";
    executable = true;
    text = ''
      #!${pkgs.execline}/bin/execlineb -S0
      ${s6Init args} "/run/s6"
    '';
  };

  s6Init = {
    oneshotPres,
    oneshotPosts,
    longRuns,
    # If true, all processes are killed in s6 finish script!
    inPidNamespace ? false
  }: pkgs.writeTextFile {
    name = "init";
    executable = true;
    text = ''
      #!${pkgs.execline}/bin/execlineb -S0

      ${pkgs.execline}/bin/export PATH ${path}

      ${pkgs.execline}/bin/if {

      ifelse { s6-test $# -ne 1 }
      { if { s6-echo "Usage: $0 STATE-DIR" } exit 1 }

      ifelse { s6-test -e $1 }
      { if { s6-echo The state directory $1 must not exist! Exiting. } exit 1 }

      if { s6-echo [init stage 1] Starting }

      if { s6-mkdir -p ''${1}/.s6-svscan }
      if { s6-ln -s ${genFinish inPidNamespace} ''${1}/.s6-svscan/finish }

      # Init stage 2
      background {
        if { s6-echo [init stage 2] Running oneshot services }

        ${genOneshots oneshotPres}

        if { s6-echo [init stage 2] Activate longrun services }

        # Move the service file to the scan directoy
        if { cp -r ${genS6ScanDir longRuns}/. $1 }
        # To be able to delete the state dir
        if { chmod -R 0755 $1 }

        if { s6-svscanctl -a $1 }

        ${genOneshots oneshotPosts}
      }

      ## run the rest of stage 1 with sanitized descriptors
      redirfd -r 0 /dev/null
      true
      }

      # Run the pid 1
      s6-svscan -t0 $1
    '';
  };

  # If a oneshost service fails, the s6-svscan process (which could be
  # the pid 1) if stopped.
  genOneshots = concatMapStringsSep "\n  " (s: ''
    ifelse -X -n
        { foreground
            { s6-echo [init stage 2] Start oneshot service "${s.name}" }
            ${genS6Run s}
        }
        # If the oneshot service fails, s6-svscan is stopped
        { foreground
            { s6-echo [init stage 2] Oneshot service '${s.name}' failed }
            if -n
              { s6-test -v DEBUG_S6_DONT_KILL_ON_ERROR }
              s6-svscanctl -t $1
        }
  '');

  genFinish = inPidNamespace: if inPidNamespace
    then pkgs.writeScript "s6-finish" ''
      #!${pkgs.execline}/bin/execlineb -S0
      ${pkgs.execline}/bin/export PATH ${path}

      # Sync before TERM'n
      ${pkgs.execline}/bin/foreground { s6-echo "[init stage 3] syncing disks." }
      foreground { s6-sync }

      # Kill everything, gently.
      foreground { s6-echo "[init stage 3] sending all processes the TERM signal." }
      foreground { s6-nuke -th } # foreground is process 1: it survives
      foreground { s6-sleep 3 }

      # Last message, then close our pipes and give the logger some time.
      foreground { s6-echo "[init stage 3] sending all processes the KILL signal and exiting." }
      fdclose 1 fdclose 2
      s6-sleep -m 200

      # Kill everything, brutally.
      foreground { s6-nuke -k } # foreground is process 1: it survives again

      # Reap all the zombies then sync, and we're done.
      wait { }
      foreground { s6-sync }
    ''
    else pkgs.writeScript "s6-finish" ''
      #!${pkgs.s6PortableUtils}/bin/s6-echo [init stage 3] Soft finish because not in a pid namespace!
    '';

  genS6ScanDir = services: pkgs.runCommand "s6-scandir" {} (''
    mkdir -p $out
  '' + (concatMapStringsSep "\n" (genS6ServiceDir) services));

  genS6ServiceDir = service: ''
    mkdir $out/${service.name}
    ln -s ${genS6Run service} $out/${service.name}/run
    ln -s ${genS6Finish service} $out/${service.name}/finish
    ${optionalString (service.execLogger != null) ''
      mkdir $out/${service.name}/log
      ln -s ${genS6Log service} $out/${service.name}/log/run
    ''
    }
  '';

  genS6Run = {
    name,
    type,
    environment,
    execStart,
    workingDirectory,
    user,
    ...
  }:
    pkgs.writeTextFile {
      name = "${name}-run";
      executable = true;
      text = ''
        #!${pkgs.execline}/bin/execlineb -P
        fdmove -c 2 1
        ${optionalString (user != "root") "${pkgs.s6}/bin/s6-setuidgid ${user}"}
        ${optionalString (workingDirectory != null) "cd ${workingDirectory}"}
        ${optionalString (environment != {}) "${pkgs.s6}/bin/s6-envdir ${envDir environment}"}
        ${execStart}
        '';
    };
  
  genS6Finish = { name, restartOnFailure, ... }: pkgs.writeTextFile {
    name = "${name}-finish";
    executable = true;
    text = ''
      #!${pkgs.execline}/bin/execlineb -S0
    '' + optionalString (restartOnFailure == false) ''

      ${pkgs.execline}/bin/export PATH ${path}

      ${pkgs.execline}/bin/if {
        if { s6-test $\{1} -ne 0 }
        if { s6-test $\{1} -ne 256 }
        s6-svscanctl -t ../
      }
    '';
  };

  genS6Log = { name, execLogger, user, ... }:
    pkgs.writeTextFile {
      name = "${name}-log";
      executable = true;
      text = ''
        #!${pkgs.execline}/bin/execlineb -P
        ${execLogger}
      '';
    };
}
