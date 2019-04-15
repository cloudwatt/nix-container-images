{ pkgs, config, lib, ...}:

with lib;

let
  cfg = config;
in
{
  options = {
    image = {
      name = mkOption {
        type = types.str;
        description = ''
          The name of the image
        '';
      };
      tag = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The tag of the image
        '';
      };
      run = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra commands run at container build time
        '';
      };
      env = mkOption {
        type = types.attrs;
        default = {};
        description = ''
          Environment variables
        '';
      };
      entryPoint = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Entry point command list
        '';
      };
      exposedPorts = mkOption {
        type = types.attrs;
        default = {};
        description = ''
          Ports exposed by the container
        '';
      };
      from = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = ''
          The parent image
        '';
      };
      interactive = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Add packages for an interactive use of the container
          (bashInteractive, coreutils)
        '';
      };
    };
  };

  config = {
    image.run = ''
      mkdir -m 777 tmp
    '';
    environment.systemPackages = optionals cfg.image.interactive [ pkgs.bashInteractive pkgs.coreutils ];
  };

}
