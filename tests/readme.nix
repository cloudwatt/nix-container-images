{ pkgs, lib, ... }:

{
  readme1 =
    lib.makeImage ({ pkgs, ... }: {
      config.image = {
        name = "hello";
        entryPoint = [ "${pkgs.hello}/bin/hello" ];
      };
    });
  
  readme2 =
    lib.makeImage ({ pkgs, ... }: {
      config = {
        image.name = "s6";
        s6.services.nginx = {
          execStart = ''${pkgs.nginx}/bin/nginx -g "daemon off;"'';
        };
      };
    });

  readme3 =
    lib.makeImage ({ pkgs, ... }: {
      config = {
        image.name = "nixos";
        environment.systemPackages = [ pkgs.coreutils ];
        users.users.alice = {
          isNormalUser = true;
        };
      };
    });
  readme4 =
    lib.makeImage ({ pkgs, ... }: {
      config = {
        image.name = "nginx";
        # Yeah! It is the NixOS module!
        services.nginx.enable = true;
      };
    });
}  
