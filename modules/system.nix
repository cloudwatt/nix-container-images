{ config, lib, ...}:

with lib;

{
  options = {
    system.build = mkOption {
      internal = true;
      default = {};
      type = types.attrs;
      description = ''
        Attribute set of derivations used to setup the system.
      '';
    };
  };
  
  config = {
    # This is to remove sytemd dependencies
    # { startSession = true; allowNullPassword = true; showMotd = true; updateWtmp = true; }
    security.pam.services.login = mkOverride 1 { startSession = false; };

    environment.extraInit = ''
      export PATH=/bin:$PATH
    '';
  };
}
