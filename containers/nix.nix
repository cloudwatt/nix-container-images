{ pkgs, config, ...}:

{
  imports = [ ];
  config = {
    environment.etc.test.text = "iopiop";
  };
}
