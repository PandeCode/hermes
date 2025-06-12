
## Binary Cache

This project uses [Cachix](https://cachix.org) for faster builds:

```bash
cachix use charon
```


### Option B: Pin it in `nixConfig` (flake-level)
Inside your `flake.nix`, add:

```nix
{
  nixConfig = {
    extra-substituters = [ "https://charon.cachix.org" ];
    extra-trusted-public-keys = [
      "charon.cachix.org-1:epdetEs1ll8oi8DT8OG2jEA4whj3FDbqgPFvapEPbY8="
    ];
  };

  # ... rest of the flake
}
