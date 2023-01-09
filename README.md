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

### Sona

#### ppom's config

This repository resides [here](https://framagit.org/ppom/config/) and its `bin/` directory should be symlinked as `/home/ao/bin`.

### Musi

Funkwhale, Nextcloud, and Collabora run in Docker, which I'm not proud of.

## License

All work here is licensed under the AGPLv3.
Work upstreamed to [nixpkgs](https://github.com/NixOS/nixpkgs) will be licensed under the MIT license.
