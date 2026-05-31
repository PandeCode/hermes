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

#### make stock vim better

Vim is installed by default on alot of systems, stock vim is annoying to use

`TODO` have a function in lua that dumps all keymaps that are not (lua plain functions or calls to lua functions)

for now when i ssh into a new server:
```bash
rm -fr ~/.vimrc
curl https://raw.githubusercontent.com/tpope/vim-sleuth/refs/heads/master/plugin/sleuth.vim >> ~/.vimrc
curl https://raw.githubusercontent.com/tpope/vim-abolish/refs/heads/master/plugin/abolish.vim >> ~/.vimrc
curl https://raw.githubusercontent.com/tpope/vim-sensible/refs/heads/master/plugin/sensible.vim >> ~/.vimrc
curl https://raw.githubusercontent.com/tpope/vim-unimpaired/refs/heads/master/plugin/unimpaired.vim >> ~/.vimrc
curl https://raw.githubusercontent.com/tpope/vim-surround/refs/heads/master/plugin/surround.vim >> ~/.vimrc
curl https://raw.githubusercontent.com/tpope/vim-commentary/refs/heads/master/plugin/commentary.vim >> ~/.vimrc
```

there's also this `tpope/vim-fugitive` but its not as simple, ill probably write a script to install a bunch more plugins
