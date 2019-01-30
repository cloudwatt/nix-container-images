# Run init scripts in the builder for testing purposes

{ pkgs, lib }:

with lib;

let
  makeInit = c: (lib.makeImage c).init;
  makeConfig = c: (lib.makeImage c).config;

  # Run init script in background adn redirect its stdout to a file. A
  # test script can use this file to do some tests
  runS6Test = test: let
    env = concatStringsSep "\n" (mapAttrsToList (n: v: "export ${n}=${v}") (attrByPath ["env"] {} test));
    run = pkgs.runCommand "runS6-${test.config.image.name}" { } ''
      ${env}

      echo "Running ${makeInit test.config}"...
      ${makeInit test.config} s6-state > s6-log &
      S6PID=$!
      tail -f s6-log &

      for i in `seq 1 10`;
      do
        if ${pkgs.writeScript "runS6-testscript" test.testScript} s6-log
        then
          mkdir $out
          cp s6-log $out/
          echo "ok" > $out/result
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
    # We add the config attribute for debugging
    run // { config = makeConfig (test.config); };

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
      grep -q "init stage 3" $1
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
      grep -q "init stage 3" $1
    '';
  };

  # Oneshot service can have dependencies
  dependentOneshot = {
    config = {
      image.name = "dependentOneshot";
      systemd.services.example-1 = {
        script = "echo example-1: MUSTNOTEXISTELSEWHERE_1";
        after = [ "example-2.service" ];
        serviceConfig.Type = "oneshot";
      };
      systemd.services.example-2 = {
        script = "echo example-2: MUSTNOTEXISTELSEWHERE_2";
        serviceConfig.Type = "oneshot";
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell}
      set -e
      grep -q MUSTNOTEXISTELSEWHERE_1 $1
      grep -q MUSTNOTEXISTELSEWHERE_2 $1
      grep MUSTNOTEXISTELSEWHERE $1 | sort --check --reverse
    '';
  };

  # OneshotPost service can have dependencies
  # example-1 is executed after example-2
  oneshotPost = {
    config = {
      image.name = "oneshotPost";

      systemd.services.example-1 = {
        script = "sleep 2; echo example-1: MUSTNOTEXISTELSEWHERE_1";
        after = [ "example-2.service" ];
        serviceConfig.Type = "oneshot";
      };
      systemd.services.example-2 = {
        script = "echo example-2: MUSTNOTEXISTELSEWHERE_2";
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell}
      set -e
      grep -q MUSTNOTEXISTELSEWHERE_1 $1
      grep -q MUSTNOTEXISTELSEWHERE_2 $1
      grep MUSTNOTEXISTELSEWHERE $1 | head -n2 | sort --check --reverse
    '';
  };

  path = {
    config = {
      image.name = "path";

      systemd.services.path = {
        script = "hello";
        path = [ pkgs.hello ];
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell} -e
      grep -q 'Hello, world!' $1
    '';
  };

  # Environment variables are propagated to the init script
  propagatedEnv = {
    config = {
      image.name = "propagatedEnv";
      systemd.services.exemple.script = "echo $IN_S6_INIT_TEST";
    };
    testScript = ''
      #!${pkgs.stdenv.shell} -e
      grep -q '^1$' $1
    '';
    env = { IN_S6_INIT_TEST = "1"; };
  };

  # Service environment variables are available
  env = {
    config = {
      image.name = "env";
      s6.services.exemple = {
        environment = { "TEST_ENV" = "1"; };
        script = "echo $TEST_ENV";
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell} -e
      grep -q '^1$' $1
    '';
  };

  # The special environment variable DEBUG_S6_DONT_KILL_ON_ERROR can
  # be used to not kill container when a oneshot fails
  s6DontTerminateOnError = {
    config = {
      image.name = "debugS6DontKillOnError";
      systemd.services.fail = {
        script = "exit 1";
        serviceConfig.Type = "oneshot";
      };
      s6.services.longRun = {
        script = "exit 2";
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell} -e
      sleep 5
      ! grep -q "finish" $1
    '';
    env = { S6_DONT_TERMINATE_ON_ERROR = "1"; };
  };

  s6SimpleService = {
    config = {
      image.name = "s6SimpleService";
      s6.services.simple = {
        execStart = "${pkgs.hello}/bin/hello";
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell} -e
      grep -q Hello $1
    '';
  };

  # Prestart is executed before ExecStart
  preStart = {
    config = {
      image.name = "preStart";
      systemd.services.example = {
        preStart = "echo MUSTNOTEXISTELSEWHERE_1";
        script = ''
          echo MUSTNOTEXISTELSEWHERE_2
        '';
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell} -e
      grep -q MUSTNOTEXISTELSEWHERE_1 $1
      grep -q MUSTNOTEXISTELSEWHERE_2 $1
      grep MUSTNOTEXISTELSEWHERE $1 | sort --check
    '';
  };

  workingDirectory = {
    config = {
      image.name = "workingDirectory";
      s6.services.example = {
        workingDirectory = "/tmp";
        script = ''
          echo $PWD
        '';
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell} -e
      grep -q /tmp $1
    '';
  };

  oneshotPre = {
    config = {
      image.name = "oneshotPre";
      s6.services.pre = {
        type = "oneshot-pre";
        script = ''
          echo oneshot-pre
        '';
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell} -e
      grep -q oneshot-pre $1
    '';
  };

  logger = {
    config = {
      image.name = "logger";
      s6.services.logger = {
        execLogger = ''${pkgs.gnused}/bin/sed -u "s/^/prefix - /"'';
        script = "echo log line";
        restartOnFailure = true;
      };
    };
    testScript = ''
      #!${pkgs.stdenv.shell} -e
      grep -q "prefix - log line" $1
    '';
  };

}
