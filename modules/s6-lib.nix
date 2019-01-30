# FIXME: This file should be moved to lib/ but I fail to make it
# available for the NixOS module system...

{ pkgs }:

with pkgs.lib;

let
  envDir = env: pkgs.runCommand "env-dir" {} (''
    mkdir $out
  '' + concatStringsSep "\n" (mapAttrsToList (n: v: "echo ${v} > $out/${n}") env));

  # The init script binary environment
  #
  # Init script uses absolute path for binaries. This is a little bit
  # verbose, but it simplifies a lot the PATH environment variable
  # managment. Since init script itself doesn't rely on the PATH, we
  # can easily propagate the PATH variable from from the environment
  # to service scripts.
  e = let
    env = pkgs.buildEnv {
      name = "init-path";
      paths = with pkgs; [ execline s6PortableUtils s6 coreutils ];
    };
  in "${env}/bin";

in rec {

  s6InitWithStateDir = args: pkgs.writeTextFile {
    name = "init-with-state-dir";
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
      #!${e}/execlineb -S0

      ${e}/if {

      ${e}/ifelse { ${e}/s6-test $# -ne 1 }
      { ${e}/if { ${e}/s6-echo "Usage: $0 STATE-DIR" } exit 1 }

      ${e}/ifelse { ${e}/s6-test -e $1 }
      { ${e}/if { ${e}/s6-echo The state directory $1 must not exist! Exiting. } ${e}/exit 1 }

      ${e}/if { ${e}/s6-echo [init stage 1] Starting }

      ${e}/if { ${e}/s6-mkdir -p ''${1}/.s6-svscan }
      ${e}/if { ${e}/s6-ln -s ${genFinish inPidNamespace} ''${1}/.s6-svscan/finish }

      # Init stage 2
      ${e}/background {
        ${e}/if { ${e}/s6-echo [init stage 2] Running oneshot services }

        ${genOneshots oneshotPres}

        ${e}/if { ${e}/s6-echo [init stage 2] Activate longrun services }

        # Move the service file to the scan directoy
        ${e}/if { ${e}/cp -r ${genS6ScanDir longRuns}/. $1 }
        # To be able to delete the state dir
        ${e}/if { ${e}/chmod -R 0755 $1 }

        ${e}/if { ${e}/s6-svscanctl -a $1 }

        ${genOneshots oneshotPosts}
      }

      ## run the rest of stage 1 with sanitized descriptors
      ${e}/redirfd -r 0 /dev/null
      ${e}/true
      }

      # Run the pid 1
      ${e}/s6-svscan -t0 $1
    '';
  };

  # If a oneshost service fails, the s6-svscan process (which could be
  # the pid 1) if stopped.
  genOneshots = concatMapStringsSep "\n  " (s: ''
    ${e}/foreground {
      ${e}/if -X -n
        { ${e}/foreground
            { ${e}/s6-echo [init stage 2] Start oneshot service "${s.name}" }
            ${genS6Run s}
        }
        # If the oneshot service fails, s6-svscan is stopped
        ${e}/foreground
            { ${e}/s6-echo [init stage 2] Oneshot service '${s.name}' failed }
            ${e}/if -n
              { ${e}/s6-test -v S6_DONT_TERMINATE_ON_ERROR }
              ${e}/foreground { ${e}/s6-svscanctl -t $1 }
              ${e}/exit 1
    }
  '');

  genFinish = inPidNamespace: if inPidNamespace
    then pkgs.writeScript "s6-finish" ''
      #!${e}/execlineb -S0

      # Sync before TERM'n
      ${e}/foreground { ${e}/s6-echo "[init stage 3] syncing disks." }
      ${e}/foreground { ${e}/s6-sync }

      # Kill everything, gently.
      ${e}/foreground { ${e}/s6-echo "[init stage 3] sending all processes the TERM signal." }
      ${e}/foreground { ${e}/s6-nuke -th } # foreground is process 1: it survives
      ${e}/foreground { ${e}/s6-sleep 3 }

      # Last message, then close our pipes and give the logger some time.
      ${e}/foreground { ${e}/s6-echo "[init stage 3] sending all processes the KILL signal and exiting." }
      ${e}/fdclose 1 ${e}/fdclose 2
      ${e}/s6-sleep -m 200

      # Kill everything, brutally.
      ${e}/foreground { ${e}/s6-nuke -k } # foreground is process 1: it survives again

      # Reap all the zombies then sync, and we're done.
       ${e}/wait { }
      ${e}/foreground { ${e}/s6-sync }
    ''
    else pkgs.writeScript "s6-finish" ''
      #!${e}/s6-echo [init stage 3] Soft finish because not in a pid namespace!
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
        #!${e}/execlineb -P
        ${e}/fdmove -c 2 1
        ${optionalString (user != "root") "${e}/s6-setuidgid ${user}"}
        ${optionalString (workingDirectory != null) "${e}/cd ${workingDirectory}"}
        ${optionalString (environment != {}) "${e}/s6-envdir ${envDir environment}"}
        ${execStart}
      '';
    };
  
  genS6Finish = { name, restartOnFailure, ... }: pkgs.writeTextFile {
    name = "${name}-finish";
    executable = true;
    text = ''
      #!${e}/execlineb -S0
      ${e}/foreground { ${e}/s6-echo "[init] Service '${name}' terminates with exit code $1" }
    '' +
        (if (restartOnFailure == false)
        then ''
          ${e}/if { ${e}/s6-test $\{1} -ne 0 }
          ${e}/if { ${e}/s6-test $\{1} -ne 256 }
          ${e}/foreground { ${e}/s6-svc -d ./ }
          ${e}/if -n
            { ${e}/s6-test -v S6_DONT_TERMINATE_ON_ERROR }
            ${e}/s6-svscanctl -t ../
        ''
        else ''
          ${e}/foreground { ${e}/s6-echo "[init] Service '${name}' will be restarted" }
        '');
  };

  genS6Log = { name, execLogger, user, ... }:
    pkgs.writeTextFile {
      name = "${name}-log";
      executable = true;
      text = ''
        #!${e}/execlineb -P
        ${execLogger}
      '';
    };
}
