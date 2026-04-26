# hermes

## Run

```bash
nix run github:pandecode/hermes#fun --accept-flake-config --extra-experimental-features flakes --extra-experimental-features nix-command --override-input nixpkgs nixpkgs
```


```bash
nix run github:pandecode/hermes
nix run github:pandecode/hermes#minimal
nix run github:pandecode/hermes#python
nix run github:pandecode/hermes#cxx
nix run github:pandecode/hermes#rust
nix run github:pandecode/hermes#go
nix run github:pandecode/hermes#web
nix run github:pandecode/hermes#fun
nix run github:pandecode/hermes#full
```

With flakes enabled and Override nixpkgs:

```bash
--accept-flake-config
--accept-flake-config --extra-experimental-features flakes --extra-experimental-features nix-command
--accept-flake-config --override-input nixpkgs nixpkgs
--accept-flake-config --extra-experimental-features flakes --extra-experimental-features nix-command --override-input nixpkgs nixpkgs
```

## Binary Cache

Add to your `flake.nix`:

```nix
{
  nixConfig = {
    extra-substituters = [ "https://charon.cachix.org" ];
    extra-trusted-public-keys = [
      "charon.cachix.org-1:epdetEs1ll8oi8DT8OG2jEA4whj3FDbqgPFvapEPbY8="
    ];
  };
}
```

## TODO

- Home manager modules
- Fennel docsets setup declarative:
  ```bash
  mkdir -p $HOME/.local/share/fennel-ls/docsets/
  curl -o $HOME/.local/share/fennel-ls/docsets/nvim.lua https://git.sr.ht/~micampe/fennel-ls-nvim-docs/blob/main/nvim.lua
  ```
- Load `.nvimrc.lua` / `.nvimrc.vim` / `.nvimrc.fnl` from project root
- Custom LSP handler for bash: `man $cmd || $cmd -h || $cmd --help`
- Learn new treesitter API
- Explore FFI usage
- Eval line/block of lua/fennel
- vlime
