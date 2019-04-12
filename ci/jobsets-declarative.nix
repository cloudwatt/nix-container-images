{ nixpkgs, declInput, pulls }:
let
  pkgs = import nixpkgs {};
  prs = builtins.fromJSON (builtins.readFile pulls);
  prJobsets =  pkgs.lib.mapAttrs (num: info:
    { enabled = 1;
      hidden = false;
      description = "PR ${num}: ${info.title}";
      nixexprinput = "nixexpr";
      nixexprpath = "ci/jobset.nix";
      checkinterval = 60;
      schedulingshares = 20;
      enableemail = false;
      emailoverride = "";
      keepnr = 1;
      inputs = {
        nixexpr = {
          type = "git";
          value = "git://github.com/${info.base.repo.owner.login}/${info.base.repo.name}.git pull/${num}/head";
          emailresponsible = false;
        };
        nixpkgs = {
          value = "https://github.com/NixOS/nixpkgs f52505fac8c82716872a616c501ad9eff188f97f";
          type = "git";
          emailresponsible = false;
        };
      };
    }
  ) prs;
  desc = prJobsets // {
    trunk = {
      description = "Build master of cloudwatt/nix-container-images";
      checkinterval = 60;
      enabled = 1;
      nixexprinput = "nixexpr";
      nixexprpath = "ci/jobset.nix";
      schedulingshares = 100;
      enableemail = false;
      emailoverride = "";
      keepnr = 3;
      hidden = false;
      inputs = {
        nixexpr = {
          value = "https://github.com/cloudwatt/nix-container-images ci";
          type = "git";
          emailresponsible = false;
        };
        # Only used by Niv to get its fetchers.
        # Belongs to branch 19.03.
        nixpkgs = {
          value = "https://github.com/NixOS/nixpkgs f52505fac8c82716872a616c501ad9eff188f97f";
          type = "git";
          emailresponsible = false;
        };
      };
    };
  };
  
in {
  jobsets = pkgs.runCommand "spec.json" {} ''
    cat >$out <<EOF
    ${builtins.toJSON desc}
    EOF
  '';
}
