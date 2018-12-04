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

- `nix`: basic single user installation
- `example`: show some supported NixOS modules

They can be built with `nix-build`.

# Supported NixOS modules

Currently, the goal is to reuse existing NixOS modules. Since they
cannot be used out-of-box (access to `/` for instance), only some of
them are partially supported...

- `users`: create users and groups
- `nix`: configure Nix
- `environment.etc`: create files in `/etc`


# Todos / Limitations

- Systemd can not be used; it is bypassed (see [fake.nix](modules/fake.nix))
- Should we really try to use NixOS modules?
- Reduce number of files installed by default
- Do not have to patch `nix-daemon.nix`
- Do not have to patch `update-users-groups.pl`
