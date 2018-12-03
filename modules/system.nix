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

    # TODO: Really useless?
    # system.build.earlyMountScript = "";
    # users.ldap = {};
    
    environment.extraInit = ''
      export PATH=/bin:$PATH
    '';
  };
}
