{ config, lib, ...}:

with lib;

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
    };
  };

  config = {
    image.run = ''
      mkdir -m 777 tmp
    '';
  };

}
