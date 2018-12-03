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
    };
  };
}
