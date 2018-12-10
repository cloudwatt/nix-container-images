{ pkgs }:

with pkgs.lib;

rec {
  s6FdNum = "42";
  s6Prefix = "/etc/s6";

  attrToEnv = env: concatStringsSep "\n" (mapAttrsToList (n: v: ''export ${n}="${v}"'') env);

  genS6Run = { type ? "simple", environment ? {}, name, execStart ? "", chdir ? "", user ? "root", execStartPre ? "", notifyCheck ? "", after ? [], ... }:
    let
      # If execStartPre is defined we create a bash script
      # to run it before the execStart. This allows to export
      # env variables in the execStartPre for the execStart.
      start =
        if execStartPre != "" || environment != {} then
          "${pkgs.writeShellScriptBin "start-${name}" ''
            set -e
            ${attrToEnv environment}
            ${execStartPre}
            exec ${execStart}

          ''}/bin/start-${name}"
        else
          execStart;
      # If start succeed write \n to the notification fd and close it
      # If start fails close the notification fd and return start exit code
      # FIXME: can't get the return code of ${start}
      startOneShot = ''
        ifte -X {
          fdswap 1 ${s6FdNum}
          echo -e "\n"
          fdswap ${s6FdNum} 1
          fdclose ${s6FdNum}
          exit 0
        }
        {
          fdclose ${s6FdNum}
          exit 100
        }
        ${start}
      '';
      # When we need to wait on some service check if the service supports
      # notifications. If it does wait on 'U' event. Otherwise wait in 'u'
      # event.
      waitFor = name: ''
        if {
          ifelse { s6-test -f ${s6Prefix}/${name}/notification-fd }
          {
            s6-svwait -U -t 0 ${s6Prefix}/${name}
          }
          s6-svwait -u -t 0 ${s6Prefix}/${name}
        }
      '';
    in
      pkgs.writeTextFile {
        name = "${name}-run";
        executable = true;
        text = ''
          #!${pkgs.execline}/bin/execlineb -P
          fdmove -c 2 1
          ${concatStrings (map waitFor after)}
          ${optionalString (notifyCheck != "" && type == "notify") "s6-notifyoncheck -n0"}
          ${optionalString (user != "root") "s6-setuidgid ${user}"}
          ${optionalString (chdir != "") "cd ${chdir}"}
          ${if type == "oneshot" then startOneShot else start}
        '';
      };

  # When type is oneshot, exit with 125 will make s6 to not restart the service
  # When stopOnFailure is true and exit code if different than 0 and 256 we stop s6-svscan
  # 256 code is received if the process was stopped by s6 (not a crash)
  genS6Finish = { type, name, ... }: pkgs.writeTextFile {
    name = "${name}-finish";
    executable = true;
    text = ''
      #!${pkgs.execline}/bin/execlineb -S1
    '' + (if (type == "oneshot")
      then "exit 125"
      else "exit 0");
  };

  genS6NotificationFd = { name, ... }:
    pkgs.writeTextFile {
      name = "${name}-notification-fd";
      text = s6FdNum;
    };
}
