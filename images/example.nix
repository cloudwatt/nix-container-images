{ pkgs, config, ...}:

{
  config = {

    image = {
      name = "hello";
      tag = "latest";
    };

    environment.systemPackages = [ pkgs.hello ];

    users.users.alice = {
      isNormalUser = true;
      home = "/home/alice";
      description = "Alice Foobar";
      extraGroups = [ "wheel" ];
    };
  };
}
