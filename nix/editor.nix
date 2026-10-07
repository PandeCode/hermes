# builds hermes: neovim wrapped with my plugins, this config and the tools of
# one profile from nixbuilds' toolsets
{
  pkgs,
  neovim,
  vlime-src,
  src,
}:

let
  inherit (pkgs) lib;

  # pname is the opt directory name that lz.n packadds
  vlime = pkgs.vimUtils.buildVimPlugin {
    pname = "vlime";
    version = vlime-src.shortRev;
    src = vlime-src;
  };

  eagerPlugins = with pkgs.vimPlugins; [
    lz-n
    mini-nvim
    snacks-nvim

    nvim-lspconfig
    none-ls-nvim
    plenary-nvim

    nvim-treesitter.withAllGrammars
    nvim-treesitter-context
    nvim-treesitter-textobjects

    rainbow-delimiters-nvim

    nvim-notify
    nui-nvim
    noice-nvim

    blink-cmp

    friendly-snippets
    gitsigns-nvim
    parinfer-rust

    oil-nvim

    cord-nvim

    vim-abolish # tpope is the og goat
    vim-eunuch
  ];

  # installed under opt, fnl/plugins.fnl and fnl/dap.fnl tell lz.n when to
  # packadd each one
  lazyPlugins = with pkgs.vimPlugins; [
    zig-vim

    nvim-dap

    nvim-dap-view

    nvim-dap-virtual-text

    neogen

    vim-wakatime
    vim-visual-multi
    vim-wordmotion
    vim-sleuth

    rustaceanvim

    firenvim

    vlime
    refactoring-nvim
  ];

  rustEnv = [
    "--set"
    "RUST_SRC_PATH"
    "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}"
  ];

  luaEnv = [
    "--prefix"
    "LUA_PATH"
    ";"
    "${pkgs.luajitPackages.fennel}/share/lua/5.1/?.lua;${pkgs.luajitPackages.fennel}/share/lua/5.1/?/init.lua"
  ];

  webEnv = [
    "--set"
    "VSCODE_FIREFOX_DEBUG"
    "${pkgs.vscode-extensions.firefox-devtools.vscode-firefox-debug}/share/vscode/extensions/firefox-devtools.vscode-firefox-debug"
  ];

  # extra environment per profile, on top of the profile's tools
  profileEnv = {
    # keep-sorted start
    full = rustEnv ++ webEnv;
    rust = rustEnv;
    web = webEnv;
    # keep-sorted end
  };

  mkEditor =
    {
      # one of the profiles in nixbuilds' toolsets
      profile ? "full",
      # nix expressions nixd evaluates for option completion
      nixd ? { },
    }:
    pkgs.wrapNeovimUnstable neovim {
      plugins =
        eagerPlugins
        ++ map (plugin: {
          inherit plugin;
          optional = true;
        }) lazyPlugins;
      viAlias = true;
      vimAlias = true;

      wrapperArgs = [
        "--set"
        "NVIM_APPNAME"
        "hermes"
        "--prefix"
        "PATH"
        ":"
        (lib.strings.makeBinPath pkgs.toolsets.profiles.${profile})
      ]
      ++ luaEnv
      ++ profileEnv.${profile} or [ ];

      luaRcContent = ''
        vim.opt.runtimepath:prepend([[${src}]])
        vim.opt.runtimepath:append([[${src}/after]])

        vim.g.nix_nixd_nixpkgs = "import ${pkgs.path} {}"
        ${lib.strings.optionalString (nixd ? nixos) "vim.g.nix_nixd_nixos_options = [[${nixd.nixos}]]"}
        ${lib.strings.optionalString (
          nixd ? home-manager
        ) "vim.g.nix_nixd_home_manager_options = [[${nixd.home-manager}]]"}

        dofile([[${src}/init.lua]])
      '';
    };
in

lib.customisation.makeOverridable mkEditor { }
