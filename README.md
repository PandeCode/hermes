## Comamnds to run

```bash
nix run github:pandecode/hermes --accept-flake-config
```

```bash
nix run github:pandecode/hermes --accept-flake-config --override-input nixpkgs nixpkgs
```

```bash
nix run github:pandecode/hermes --accept-flake-config --extra-experimental-features flakes --extra-experimental-features nix-command
```

```bash
nix run github:pandecode/hermes --accept-flake-config --extra-experimental-features flakes --extra-experimental-features nix-command --override-input nixpkgs nixpkgs
```

## Binary Cache

This project uses [Cachix](https://cachix.org) for faster builds:

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
```

Fennel

# TODO

for home config modules

mkdir -p $HOME/.local/share/fennel-ls/docsets/
curl -o $HOME/.local/share/fennel-ls/docsets/nvim.lua https://git.sr.ht/~micampe/fennel-ls-nvim-docs/blob/main/nvim.lua

Load a ".nvimrc.lua" or ".nvimrc.vim" or ".nvimrc.fnl"

Custom in client lsp for bash to do:

- man $cmd || $cmd -h || $cmd --help

Learn new treesitter api

See if ffi can be used
