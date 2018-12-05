{ pkgs, config, ...}:

{
  config = {
    image = {
      name = "systemd";
      tag = "latest";
    };

    systemd.services.systemd-daemon = {
      environment = { OUTPUT = "output"; };
      script = ''
        while true; do
          echo $OUTPUT
          sleep 1
        done
      '';
    };
  };
}
