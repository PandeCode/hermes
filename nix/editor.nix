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

  vlime = pkgs.vimUtils.buildVimPlugin {
    name = "vlime";
    src = vlime-src;
  };

  eagerPlugins = with pkgs.vimPlugins; [
    lz-n
    mini-nvim
    snacks-nvim

    neogen

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

    trouble-nvim

    blink-cmp
    blink-pairs
    blink-indent

    friendly-snippets
    gitsigns-nvim
    parinfer-rust

    oil-nvim

    cord-nvim

    vim-abolish # tpope is the og goat
    vim-eunuch
  ];

  lazyPlugins = with pkgs.vimPlugins; [
    zig-vim

    nvim-dap
    nvim-dap-python

    nvim-dap-view

    nvim-dap-virtual-text
    nvim-nio

    vim-wakatime
    vim-visual-multi
    vim-wordmotion
    vim-sleuth

    rustaceanvim

    firenvim

    vlime
    refactoring-nvim
  ];

  toPluginEntry = lazy: p: ''
    ["${p.pname or p.name}"] = {
      path = [[${p}]],
      url = [[${p.meta.homepage or ""}]],
      lazy = ${lib.trivial.boolToString lazy}
    },
  '';

  lldb = pkgs.vscode-extensions.vadimcn.vscode-lldb;

  lldbEnv = [
    "--set"
    "CODELLDB_PATH"
    "${lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb"
    "--set"
    "LIBLLDB_PATH"
    "${lldb}/share/vscode/extensions/vadimcn.vscode-lldb/lldb/lib/liblldb.so"
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
    cxx = lldbEnv;
    full = lldbEnv ++ rustEnv ++ webEnv;
    fun = lldbEnv;
    go = lldbEnv;
    rust = lldbEnv ++ rustEnv;
    web = webEnv;
    zig = lldbEnv;
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
      plugins = eagerPlugins ++ lazyPlugins;
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

        vim.g.nix_profile = "${profile}"

        vim.g.nix_nixd_nixpkgs = "import ${pkgs.path} {}"
        ${lib.strings.optionalString (nixd ? nixos) "vim.g.nix_nixd_nixos_options = [[${nixd.nixos}]]"}
        ${lib.strings.optionalString (
          nixd ? home-manager
        ) "vim.g.nix_nixd_home_manager_options = [[${nixd.home-manager}]]"}

        vim.g.nix_plugins = {
          ${lib.strings.concatStrings (
            map (toPluginEntry false) eagerPlugins ++ map (toPluginEntry true) lazyPlugins
          )}
        }

        dofile([[${src}/init.lua]])
      '';
    };
in

lib.customisation.makeOverridable mkEditor { }
