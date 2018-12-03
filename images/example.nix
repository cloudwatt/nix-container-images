{}

{
  config = {
    image = {
      name = "image";
      run = "${pkgs.sleep}";
      env = {
        VERBOSE=1;
      };
      runAsRoot = "chmod...";
      multiLayering = false;
    }
    environment.etc."sleep.conf".text = "my configuration";
  }
}
