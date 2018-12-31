# Declarative container images

Write container images as NixOS machines!

```nix
lib.makeImage (
  { pkgs, ... }: {
    config = {
      image.name = "hello";

      environment.systemPackages = [ pkgs.hello ];

      # A small subset of the systemd module is implemented with s6 :/
      systemd.services.example.script = "/bin/hello";
    };
  })
```

To use `lib.makeImage` in a project, just add `overlay.nix` to the
nixpkgs overlay list. More information in the [nixpkgs
documentation](https://nixos.org/nixpkgs/manual/#sec-overlays-install).


## Available images

- [nix](images/nix.nix): basic single user installation
- [example](images/example.nix): show some supported NixOS modules
- [example-systemd](images/example-systemd.nix): supported subset of systemd modules

They can be built with `nix-build -A dockerImages`.


## Supported NixOS modules

The goal is also to reuse NixOS modules. Since they cannot be used
out-of-box (access to `/` for instance), only some of them are
partially supported.

- `users`: create users and groups
- `nix`: configure Nix
- `environment.etc`: create files in `/etc`
- `systemd`: a small subset of the systemd module is implemented with [s6](https://www.skarnet.org/software/s6/)
- `nginx`: see its [test](./tests/nginx.nix).


## Tests

Some images are tested in a NixOS vm. See the [tests directory](./tests).
To run tests:
```
nix-build -A tests.dockerImages
```


## Implementation of the NixOS systemd service interface

To be able to run some systemd services in containers,
[s6](https://www.skarnet.org/software/s6/) is used as init
system. Systemd service definitions are used to generate s6 services
with several differences in the implementation:

- all oneshot services are executed at container start up before long run services
- service dependancies are ignored
- systemd cron job are not supported


## Todos / Limitations

- Systemd implementation is fragile and approximative
- Reduce number of files installed by default in images
- Do not have to patch `nix-daemon.nix`
- Do not have to patch `update-users-groups.pl`
- Warnings on non implemented systemd features


## Tips

- To generate and run the container init script
  ```
  nix-build  -A dockerImages.example-systemd.init
  ./result S6-STATE-DIR
  ```

- To get the image used by a test `nix-build -A tests.dockerImages.nginx.image`


