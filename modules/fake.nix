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
      default = {};
    };
      
    services.sssd.enable = mkOption {
        type = types.bool;
        default = false;
      };
    krb5.enable = mkOption {
        type = types.bool;
        default = false;
      };
    services.fprintd.enable = mkOption {
        type = types.bool;
        default = false;
      };
    security.pam.usb.enable = mkOption {
        type = types.bool;
        default = false;
      };
    security.pam.oath.enable = mkOption {
        type = types.bool;
        default = false;
      };
    security.pam.mount.enable = mkOption {
        type = types.bool;
        default = false;
      };
    services.samba.syncPasswordsByPam = mkOption {
        type = types.bool;
        default = false;
      };
    virtualisation.lxc.lxcfs.enable  = mkOption {
        type = types.bool;
        default = false;
      };
    boot.specialFileSystems = mkOption {
      default = [];
      };
    boot.isContainer = mkOption {
      default = true;
      };
    programs.ssh.package = mkOption {
      default = pkgs.openssh;
      };

    users = {
      users =
        let fakeOptions = {
          openssh = mkOption {
            type = "undefined";
          };
        };
        in mkOption { options = [ fakeOptions ];};
      ldap.enable = mkOption {
        type = types.bool;
        default = false;
      }; 
    };

    systemd = mkOption {
        type = "undefined";
        default = [ "nobody" ];
        description = ''
          A list of users which will not be shown in the display manager.
        '';
      };

    boot.supportedFilesystems = mkOption {
      default = [ ];
      example = [ "btrfs" ];
      type = types.listOf types.str;
      description = "Names of supported filesystem types in the initial ramdisk.";
    };
  };
}
