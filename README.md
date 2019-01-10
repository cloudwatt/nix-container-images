# Declarative container images with Nix

This project allows you to
- make your images composable (thanks to the NixOS modules system)
- integrate the [s6](https://www.skarnet.org/software/s6/) init system in your images
- reuse NixOS modules in a container... without having to rely on systemd
- build a Nix Docker image, built with Nix


## Getting started

To build a Docker image named `hello` that runs `hello`.

```nix
lib.makeImage (
  { pkgs, ... }: {
    config.image = {
      name = "hello";
      entryPoint = [ "${pkgs.hello}/bin/hello" ];
    };
  })
```

- To build an empty image from CLI,
  ```
  nix-build -E 'with import ./default.nix{}; lib.makeImage({...}: { config.image.name = "empty"; })'
  ```

- To use `lib.makeImage` in your project, add `overlay.nix` to your
  [nixpkgs overlay list](https://nixos.org/nixpkgs/manual/#sec-overlays-install).

See [the image module](modules/image.nix) for currently supported
options.


## Use s6 as init system to run services

The [s6 module](#s6-module) can be used to build an image with an init
system. The [s6](https://www.skarnet.org/software/s6/) init system is
used to run defined `s6.services`.

```nix
lib.makeImage ({ pkgs, ... }: {
  config = {
    image.name = "s6";
    s6.services.nginx = {
      execStart = ''${pkgs.nginx}/bin/nginx -g "daemon off;"'';
    };
  };
})
```

Goals of an init system in a container are
- Proper PID 1 (no zombie processes)
- Run several services in one container
- Processes debugging (if the process is killed or died, the container
  is not necessarily killed)
- Execute initialization tasks


See [s6 module](#s6-module) details.


## (Re)Use NixOS modules

Some NixOS modules can be used, such as `users`, `etc`.

```nix
lib.makeImage ({ pkgs, ... }: {
  config = {
    image.name = "nixos";
    environment.systemPackages = [ pkgs.coreutils ];
    users.users.alice = {
      isNormalUser = true;
    };
  };
})
```

See also [supported NixOS modules](supported-nixos-modules).


## Systemd support of NixOS modules :/

It is possible to run some NixOS modules defining systemd services
thanks to a partial systemd implementation with s6.

Note this implementation is fragile, experimental and partial!

```nix
lib.makeImage ({ pkgs, ... }: {
  config = {
    image.name = "nginx";
    # Yeah! It is the NixOS module!
    services.nginx.enable = true;
  };
})
```


## Predefined images

- [nix](images/nix.nix): basic single user installation

These images can be built with `nix-build -A dockerImages`.

More configurations and images are also available in the
[tests directory](./tests).


## Supported NixOS modules

- `users`: create users and groups
- `nix`: configure Nix
- `environment.etc`: create files in `/etc`
- `systemd`: a small subset of the systemd module is implemented with [s6](https://www.skarnet.org/software/s6/)
- `nginx`: see its [test](./tests/nginx.nix).

Important: only a small subset of NixOS modules is supported. See the
[tests directory](./tests) for supported (and tested) features.


## Tests

- [s6](tests/s6.nix): s6 tests executed in the Nix build environment (fast to run but limited)
- [dockerImages](tests/): tests on Docker images executed in a NixOS VM.


## s6 module

TO BE DONE...

See module [options](modules/s6.nix) and [examples](tests/s6.nix).


## Implementation of the NixOS systemd service interface

A subset of the NixOS systemd services interface is supported and
implemented with the [s6](https://www.skarnet.org/software/s6/) init
system.

There are several differences with the NixOS systemd
implementation. The main one is the service dependency model:

- Services of type `simple` become `long-run` s6 services and dependencies are ignored
- Services of type `oneshot` become `onehost-pre` s6 services except
  if they have an `after` dependency to a `simple` service. In this
  case, they become `oneshot-post`. Dependencies between oneshot
  services are respected.


## Tips

- To generate and run the container init script as user
  ```
  nix-build  -A dockerImages.example-systemd.init
  ./result S6-STATE-DIR
  ```
- To get the image used by a test `nix-build -A tests.dockerImages.nginx.image`
- The NixOS config of an image `nix-instantiate --eval -A tests.dockerImages.nginx.image.config`
- The NixOS config of an s6 test `nix-instantiate --eval -A tests.s6.path.config.systemd`


## Related projects

- [s6-overlay](https://github.com/just-containers/s6-overlay)
- [nix-docker-nix](https://github.com/garbas/nix-docker-nix)


## Todos / Limitations

- systemd implementation is fragile
- Do not have to patch `nix-daemon.nix`
- Do not have to patch `update-users-groups.pl`
- Warnings on non implemented systemd features


## What could be improved in nixpkgs

- The base directory of NixOS activation script should be configurable. It is currently `/`
- Split service runtime and installation/build time in modules: it's hard to
  only use the part of a module that generate the configuration file
  of a service. At evaluation, a lot of modules need to be imported
  while they are only used by the service runtime part.
- Explicit dependencies between modules


