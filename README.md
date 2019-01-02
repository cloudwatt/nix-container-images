# Declarative container images

Make container images composable thanks to the NixOS modules system!

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

To use `lib.makeImage` in a project, add `overlay.nix` to your
[nixpkgs overlay list](https://nixos.org/nixpkgs/manual/#sec-overlays-install).


## Example images

- [nix](images/nix.nix): basic single user installation
- [example](images/example.nix): show some supported NixOS modules
- [example-systemd](images/example-systemd.nix): supported subset of systemd modules

These images can be built with `nix-build -A dockerImages`.

More configurations and images are also available in the
[tests directory](./tests), such as in the
[s6 test](./tests/s6.nix).


## Supported NixOS modules

- `users`: create users and groups
- `nix`: configure Nix
- `environment.etc`: create files in `/etc`
- `systemd`: a small subset of the systemd module is implemented with [s6](https://www.skarnet.org/software/s6/)
- `nginx`: see its [test](./tests/nginx.nix).

Important: only a subset of NixOS modules is supported. See the
[tests directory](./tests) for supported (and tested) features.


## Implementation of the NixOS systemd service interface

A subset of the NixOS systemd services interface is supported and
implemented with the [s6](https://www.skarnet.org/software/s6/) init
system.

There are several differences with the NixOS systemd
implementation. The main one is the service dependency model: there
are 3 types of services.

- `pre-oneshot` services: they are sequentially executed at container startup, before long runs services.
- Longrun services: all non `oneshot` services!
- `post-oneshot` services: they are sequentially executed after long
  runs services have been started. If a `oneshot` service has an after
  dependency to a long run service, it becomes a post oneshot service.

If a `oneshot` services fails, the container PID 1 is terminated. The
order of oneshot services depend on the `after` dependencies they are
defining.


## Tests

- [s6](tests/s6.nix): s6 tests executed in the Nix build environment (fast to run but limited)
- [dockerImages](tests/): tests on Docker images executed in a NixOS VM.


## Todos / Limitations

- systemd implementation is fragile
- Reduce number of files installed by default in images
- Do not have to patch `nix-daemon.nix`
- Do not have to patch `update-users-groups.pl`
- Warnings on non implemented systemd features


## Tips

- To generate and run the container init script as user
  ```
  nix-build  -A dockerImages.example-systemd.init
  ./result S6-STATE-DIR
  ```
- To get the image used by a test `nix-build -A tests.dockerImages.nginx.image`
- The NixOS config of an image `nix-instantiate --eval -A tests.dockerImages.nginx.image.config`
- The NixOS config of an s6 test `nix-instantiate --eval -A tests.s6.path.config.systemd`
