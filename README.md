**!!! This is an experimental project which is not supposed to be used (yet) !!!**

# Declarative container images

Write container images as NixOS machines!

```
makeImage (
  { pkgs, ... }: {
    config = {
      image.name = "hello";
      environment.systemPackages = [ pkgs.hello ];

      # A small subset of the systemd module is implemented with s6 :/
      systemd.services.example.script = "/bin/hello";
    };
  })
```

# Available images

- [nix](images/nix.nix): basic single user installation
- [example](images/example.nix): show some supported NixOS modules
- [example-systemd](images/example-systemd.nix): supported subset of systemd modules

They can be built with `nix-build`.

# Supported NixOS modules

Currently, the goal is to reuse existing NixOS modules. Since they
cannot be used out-of-box (access to `/` for instance), only some of
them are partially supported.

- `users`: create users and groups
- `nix`: configure Nix
- `environment.etc`: create files in `/etc`
- `systemd`: a small subset of the systemd module is implemented with [s6](https://www.skarnet.org/software/s6/)


# Todos / Limitations

- Reduce number of files installed by default
- Do not have to patch `nix-daemon.nix`
- Do not have to patch `update-users-groups.pl`
- Warnings on non implemented systemd features
- Add tests
