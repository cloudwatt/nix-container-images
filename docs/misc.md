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


