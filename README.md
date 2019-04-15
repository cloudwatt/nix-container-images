# Declarative container images with Nix

With this project you can
- make your image composable (thanks to the NixOS modules system)
- integrate the [s6](https://www.skarnet.org/software/s6/) init system in your images
- reuse some NixOS modules in a container... without relying on systemd
- make a Nix a Docker image, built by Nix


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
  nix-build -E 'with import ./default.nix{}; lib.makeImage{ config.image.name = "empty"; }'
  ```

- To use `lib.makeImage` in your project, add `overlay.nix` to your
  [nixpkgs overlay list](https://nixos.org/nixpkgs/manual/#sec-overlays-install).

The [`image`](#module-image) module section for more information.


## Use s6 as init system to run services

The [s6 module](#module-s6) can be used to build an image with an init
system. The [s6 init system](https://www.skarnet.org/software/s6/) is
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

Some goals of using an init system in a container are
- Proper PID 1 (no zombie processes)
- Run several services in one container
- Processes debugging (if the process is killed or died, the container
  is not necessarily killed)
- Execute initialization tasks


See [s6 module](#module-s6) for details.


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

See also [supported NixOS modules](#supported-nixos-modules).


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


## Module `image`

The `image` module defines common Docker image attributes, such as the
image name, the environment variables, etc. Please refer to
[the `image` options documentation](docs/options-well-supported-generated.md#imageentrypoint).


## Module `s6`

This module allows you to easily create services, managed by the
[s6 init system](https://www.skarnet.org/software/s6/). Three types of
services can be defined:

- `oneshot-pre` services are exectued sequentially at container start
  time and must terminates. They can be ordered thanks to the `after`
  option.
- `long-run` services are for daemons and are managed by `s6`. There
  is no dependencies notion on long run services.
- `oneshot-post` services are executed sequentially once all long run
  services have been started. They can also be order (`after`
  option). They are generally used to do provision started services.

Options are described in this
[generated `s6` options documentation](docs/options-well-supported-generated.md#s6services).


### How/when s6 main process is terminated

By default, if a s6 service fails, the `s6-svcscan` (PID 1 in a
container) process is terminated. A `long-run` service can set the
`restartOnFailure` option to `true` to restart the service when it
fails.

If the `S6_DONT_TERMINATE_ON_ERROR` environment variable is set,
`s6-svscan` is not terminated on service failure. This can be used to
debug interactively a failing service.


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


## Contributing

Contributions to nix-container-images through PRs are always
welcome. All PRs will be automatically tested by the [Hydra CI
server](https://hydra.nix.corp.cloudwatt.com/project/nix-container-images).