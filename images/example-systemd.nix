{ pkgs, config, ...}:

{
  config = {
    image = {
      name = "systemd";
    };

    systemd.services.script = {
      environment = { OUTPUT = "output"; };
      script = ''
        while true; do
          echo systemd.services.daemon.script with environment.OUTPUT=$OUTPUT
          sleep 1
        done
      '';
    };

    systemd.services.oneshot = {
      script = ''
        echo systemd.services.oneshot
      '';
      serviceConfig.Type = "oneshot";
    };

    systemd.services.execStart = {
      serviceConfig.ExecStart = ''${pkgs.bash}/bin/bash -c "echo serviceConfig.ExecStart"'';
    };

    systemd.services.preStart = {
      preStart = ''
        echo systemd.services.pre-start.preStart
      '';
      script = ''
        while true; do
          echo systemd.services.pre-start.script
          sleep 1
        done
      '';
    };

    systemd.services.first = {
      serviceConfig.Type = "oneshot";
      script = ''
        echo systemd.services.first begin
        sleep 3
        echo dependent services 1 system.services.first
      '';
    };

    systemd.services.second = {
      requires = [ "first.service" ];
      after = [ "first.service" ];
      script = ''
        echo dependent services 2 system.services.second
      '';
    };
  };
}
