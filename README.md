# ppom's configuration

Two nixos configuration reside here.
To use them, add a top-level `configuration.nix`
containing one of those:

```nix
{ config, pkgs, ... }:
{
  imports = [
    ./modules/sona/configuration.nix
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
