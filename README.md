**!!! This is an experimental project which is not supposed to be used (yet) !!!**

# Declarative container images

Write container images as NixOS machines!

```
makeImage (
  { pkgs, ... }: {
    config = {
      image.name = "hello";
      environment.systemPackages = [ pkgs.hello ];
    };
  })
```

# Available images

- `nix`

They can be built with `nix-build`.

# Supported NixOS modules

Currently, the goal is to reuse existing Nixos modules. They cannot
work out-of-box so only some of them are partially supported.

- `users`: create users and groups
- `nix`: configure Nix
- `environment.etc`: create files in `/etc`


# Todos

- Should we try to use NixOS modules?
- Reduce number of files installed by default
- Do not have to patch `nix-daemon.nix`
- Do not have to patch `update-users-groups.pl`
