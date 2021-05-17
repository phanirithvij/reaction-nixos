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
    ./modules/musi/configuration.nix
  ];
}
```

## Impurities

### Sona

#### ppom's config

This repository resides [here](https://framagit.org/ppom/config/) and its `bin/` directory should be symlinked as `/home/ao/bin`.

#### ppom's dwm

ppom's [`dwm` fork](https://framagit.org/ppom/dwm) should reside here: `/home/ao/prg/dwm`.

#### other packages

vtt2srt is attended in `/home/ao/prg/nix/vtt2srt`.

### Musi

TODO
- rzw
- nextcloud's docker-compose
- static websites
