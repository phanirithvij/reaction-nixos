# ppom's configuration

Three nixos configuration reside here.
To use them, add a top-level `configuration.nix`
containing one of those:

```nix
{ config, pkgs, ... }:
{
  imports = [
    ./modules/sona
  ];
}
```

```nix
{ config, pkgs, ... }:
{
  imports = [
    ./modules/akesi
  ];
}
```

```nix
{ config, pkgs, ... }:
{
  imports = [
    ./modules/musi
  ];
}
```

## Impurities

### sona

#### ppom's config

This repository resides [here](https://framagit.org/ppom/config/) and its `bin/` directory should be symlinked as `/home/ao/bin`.

### musi

Funkwhale processes run in Docker.

## License

All work here is licensed under the AGPLv3.
Work upstreamed to [nixpkgs](https://github.com/NixOS/nixpkgs) will be licensed under the MIT license.
