# Run init scripts in the builder for testing purposes

{ pkgs, lib }:

let
  makeInit = c: (lib.makeImage c).init;

  # Run init script in background adn redirect its stdout to a file. A
  # test script can use this file to do some tests
  runS6Test = test:
    pkgs.runCommand "runS6-${test.config.image.name}" { } ''
      echo "Running ${makeInit test.config}"...
      ${makeInit test.config} s6-state > s6-log &
      S6PID=$!

      for i in `seq 1 10`;
      do
        if ${pkgs.writeScript "runS6-testscript" test.testScript} s6-log
        then
          echo "ok" > $out
          exit 0
        fi

        # If s6 is down, the test fails
        if ! ${pkgs.procps}/bin/ps -p $S6PID > /dev/null;
        then
          echo "Test fails and s6-svscan is down."
          exit 1
        fi

        sleep 1
      done

      # If the timeout is reached, the test fails
      echo "Test timeout."
      exit 1
  '';

in
pkgs.lib.mapAttrs (n: v: runS6Test v) {

  # If a long run service with restart = no fails, s6-svscan
  # terminates
  stopIfLongrunNoRestartFails = {
    config = {
      image.name = "stopIfLongrunNoRestartFails";
      systemd.services.example.script = ''
        exit 1
      '';
    };
    testScript = ''
      #!${pkgs.stdenv.shell}
      grep -q "init finish" $1
    '';
  };

  # If a long run service with restart = always fails, the service is
  # restarted
  stopIfLongrunRestart = {
    config = {
      image.name = "stopIfLongrunRestart";
      systemd.services.example = {
        script = ''
          echo "restart"
          exit 1
        '';
        serviceConfig.Restart = "always";
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell} -e
      [ `grep "restart" $1 | wc -l` -ge 2 ]
    '';
  };

  # If a oneshot fails, s6-svscan terminates
  stopIfOneshotFail = {
    config = {
      image.name = "stopIfOneshotFail";
      systemd.services.example = {
        script = ''
          echo "restart"
          exit 1
        '';
        serviceConfig.Type = "oneshot";
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell}
      grep -q "init finish" $1
    '';
  };

  # Oneshot service can have dependencies
  dependentOneshot = {
    config = {
      image.name = "dependentOneshot";
      systemd.services.example-1 = {
        script = "echo example-1";
        after = [ "example-2.service" ];
        serviceConfig.Type = "oneshot";
      };
      systemd.services.example-2 = {
        script = "echo example-2";
        serviceConfig.Type = "oneshot";
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell}
      set -e
      grep -q example-1 $1
      grep -q example-2 $1
      grep "example" $1 | sort --check --reverse
    '';
  };

  # OneshotPost service can have dependencies
  # example-1 is executed after example-2
  oneshotPost = {
    config = {
      image.name = "oneshotPost";

      systemd.services.example-1 = {
        script = "sleep 2; echo example-1";
        after = [ "example-2.service" ];
        serviceConfig.Type = "oneshot";
      };
      systemd.services.example-2 = {
        script = "echo example-2;";
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell}
      set -e
      grep -q example-1 $1
      grep -q example-2 $1
      grep "example" $1 | head -n2 | sort --check --reverse
    '';
  };

}
