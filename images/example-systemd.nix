{ pkgs, config, ...}:

{
  config = {
    image = {
      name = "systemd";
      tag = "latest";
    };

    systemd.services.daemon = {
      environment = { OUTPUT = "output"; };
      script = ''
        while true; do
          echo $OUTPUT
          sleep 1
        done
      '';
    };

    systemd.services.oneshot = {
      script = ''
        echo "oneshot"
      '';
      serviceConfig.Type = "oneshot";
    };

  };
}
