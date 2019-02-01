# We add fake options because we don't want to import all NixOS
# modules.

{ config, pkgs, lib, ...}:

with lib;

{
  options = {

    services.xserver.displayManager.hiddenUsers = mkOption {
      type = types.listOf types.str;
      default = [ "nobody" ];
      description = ''
        A list of users which will not be shown in the display manager.
      '';
    };


    system.activationScripts = mkOption {
      visible = false;
      default = {};
    };
    
    services.sssd.enable = mkOption {
      visible = false;
      type = types.bool;
      default = false;
    };
    krb5.enable = mkOption {
      visible = false;
      type = types.bool;
      default = false;
    };
    services.fprintd.enable = mkOption {
      visible = false;
      type = types.bool;
      default = false;
    };
    security.pam.usb.enable = mkOption {
      visible = false;
      type = types.bool;
      default = false;
    };
    security.pam.oath.enable = mkOption {
      visible = false;
      type = types.bool;
      default = false;
    };
    security.pam.mount.enable = mkOption {
      visible = false;
      type = types.bool;
      default = false;
    };
    services.samba.syncPasswordsByPam = mkOption {
      visible = false;
      type = types.bool;
      default = false;
    };
    virtualisation.lxc.lxcfs.enable  = mkOption {
      visible = false;
      type = types.bool;
      default = false;
    };
    boot.specialFileSystems = mkOption {
      visible = false;
      default = [];
    };
    boot.isContainer = mkOption {
      visible = false;
      default = true;
    };
    programs.ssh.package = mkOption {
      visible = false;
      default = pkgs.openssh;
    };

    users = {
      users =
        let fakeOptions = {
          openssh = {};
        };
        in mkOption { options = [ fakeOptions ];};
      ldap.enable = mkOption {
        visible = false;
        type = types.bool;
        default = false;
      }; 
    };

    networking.proxy.envVars = mkOption {
      visible = false;
      type = types.attrs;
      default = {};
    };

    boot.supportedFilesystems = mkOption {
      default = [ ];
      example = [ "btrfs" ];
      type = types.listOf types.str;
      description = "Names of supported filesystem types in the initial ramdisk.";
    };

    # Required by nginx
    security.acme = mkOption {
      visible = false;
      default = {};
    };
    # Required by nginx
    networking.enableIPv6 = mkOption {
      visible = false;
      default = false;
    };
  };
}
