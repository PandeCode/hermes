self: let
  inherit (self) inputs;
  inherit (inputs) nixpkgs;
in
  system: let
    pkgs = nixpkgs.legacyPackages.${system};
    nvim = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

    eagerPlugins = with pkgs.vimPlugins; [
      lz-n
      mini-nvim
      snacks-nvim

      lz-n
      nvim-lspconfig
      none-ls-nvim
      plenary-nvim

      nvim-treesitter.withAllGrammars
      nvim-treesitter-context
      nvim-treesitter-textobjects

      nvim-notify
      nui-nvim
      noice-nvim

      mini-nvim
      snacks-nvim

      trouble-nvim
      dropbar-nvim

      # glsl_analyzer breaks, wait till next blink release
      (blink-cmp.overrideAttrs (_old: {
        src = pkgs.fetchFromGitHub {
          owner = "Saghen";
          repo = "blink.cmp";
          rev = "6731979aa370be0e5c7cc73258ce945730a515c9";
          # rev = "main";
          hash = "sha256-zADARdkrmh0bqsbvt9d+eJYpoI5y45FDa3OHQAuu4EU=";
        };
      }))

      blink-pairs
      blink-indent

      friendly-snippets
      gitsigns-nvim
      parinfer-rust

      oil-nvim

      cord-nvim
    ];

    lazyPlugins = with pkgs.vimPlugins; [
      nvim-dap

      # nvim-dap-ui
      nvim-dap-view

      nvim-dap-virtual-text
      nvim-nio

      vim-wakatime
      vim-visual-multi
      vim-wordmotion
      vim-sleuth

      haskell-tools-nvim
      rustaceanvim

      firenvim

      # vlime

      refactoring-nvim
    ];

    plugins = eagerPlugins ++ lazyPlugins;

    toPluginEntry = lazy: p: ''
      ["${p.pname or p.name}"] = {
        path = [[${p}]],
        url = [[${p.meta.homepage or ""}]],
        lazy = ${
        if lazy
        then "true"
        else "false"
      }
      },
    '';

    neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
      inherit plugins;
      # viAlias = true;
      # vimAlias = true;
    };

    # toolsets

    tools = let
      lldbTools = with pkgs; [
        vscode-extensions.vadimcn.vscode-lldb
        lldb
      ];
    in {
      base = with pkgs; [
        universal-ctags
        ripgrep
        fd
        proselint
        ast-grep
        harper
      ];

      lua = with pkgs; [
        emmylua-ls
        emmylua-check
        emmylua-doc-cli
        stylua
      ];

      fennel = with pkgs; [
        luaPackages.fennel
        fennel-ls
        fnlfmt
      ];

      nix = with pkgs; [
        nixd
        statix
        deadnix
        alejandra
      ];

      shell = with pkgs; [
        bash-language-server
        shfmt
      ];

      python = with pkgs; [
        pyright
        ruff
        black
      ];

      cxx = with pkgs;
        [
          asm-lsp
          ccls
          clang-tools
          neocmakelsp
          cmake-format
          cmake-lint
          gdb
        ]
        ++ lldbTools;

      rust = with pkgs;
        [
          cargo
          rust-analyzer
          rustc
        ]
        ++ lldbTools;

      go = with pkgs;
        [
          go
          gopls
          gotools
          go-tools
        ]
        ++ lldbTools;

      web = with pkgs; [
        bun
        vscode-langservers-extracted
        typescript-language-server
        eslint
        tailwindcss-language-server
        emmet-ls
        mermaid-cli
        wasm-language-tools
      ];

      fun = with pkgs;
        [
          sbcl

          matlab-language-server

          haskell-language-server
          cabal-install
          stack
          ghc

          ocaml
          ocamlPackages.ocaml-lsp
          # dune_3
        ]
        ++ lldbTools;
    };

    # profile definitions

    inherit (pkgs.lib) flatten;

    profiles = let
      minimal = flatten [tools.base tools.lua tools.fennel tools.nix tools.shell];
    in {
      inherit minimal;
      python = flatten [minimal tools.python];
      cxx = flatten [minimal tools.cxx];
      rust = flatten [minimal tools.rust];
      go = flatten [minimal tools.go];
      web = flatten [minimal tools.web];
      fun = flatten [minimal tools.fun];
      full = flatten [minimal tools.python tools.cxx tools.rust tools.go tools.web tools.fun];
    };

    # editor builder

    mkEditor = profile: packages: profileEnv:
      pkgs.wrapNeovimUnstable nvim (
        neovimConfig
        // {
          wrapperArgs =
            neovimConfig.wrapperArgs
            ++ [
              "--set"
              "NVIM_APPNAME"
              "hermes"
              "--prefix"
              "LUA_PATH"
              ":"
              "${pkgs.luajitPackages.fennel}/share/lua/5.1"
              "--prefix"
              "PATH"
              ":"
              "${pkgs.lib.makeBinPath packages}"
            ]
            ++ profileEnv;

          luaRcContent =
            ''
              vim.opt.runtimepath:prepend([[${self}]])

              vim.g.nix_profile = "${profile}"

              vim.g.nix_nixd_nixpkgs = "import ${pkgs.path} {}"

            ''
            + (
              if builtins.hasAttr "self" inputs
              then ''
                vim.g.nix_nixd_nixos_options = "(builtins.getFlake "path:${toString inputs.self.outPath}").nixosConfigurations.configname.options"
                vim.g.nix_nixd_home_manager_options = "(builtins.getFlake "path:${toString inputs.self.outPath}").homeConfigurations.configname.options"
              ''
              else ""
            )
            + ''
              vim.g.nix_plugins = {
                ${builtins.concatStringsSep "\n          " (
                (map (toPluginEntry false) eagerPlugins)
                ++ (map (toPluginEntry true) lazyPlugins)
              )}
              }

              dofile([[${self}/init.lua]])
            ''
            + (neovimConfig.luaRcContent or "");
        }
      );

    # editor variants

    editors = let
      luaEnv = [
        "--prefix"
        "LUA_PATH"
        ";"
        (
          pkgs.lib.concatMapStringsSep ";" (
            p: "${p}/share/lua/5.1/?.lua;${p}/share/lua/5.1/?/init.lua"
          )
          (
            with pkgs.luajitPackages; [
              fennel
            ]
          )
        )
      ];
      lldbEnv = [
        "--set"
        "CODELLDB_PATH"
        "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb"
        "--set"
        "LIBLLDB_PATH"
        "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/lldb/lib/liblldb.so"
      ];
      rustEnv = [
        "--set"
        "RUST_SRC_PATH"
        "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}"
      ];
    in {
      full = mkEditor "full" profiles.full (lldbEnv ++ rustEnv ++ luaEnv);
      minimal = mkEditor "minimal" profiles.minimal [];

      python = mkEditor "python" profiles.python [];

      rust = mkEditor "rust" profiles.rust (lldbEnv ++ rustEnv);
      cxx = mkEditor "cxx" profiles.cxx lldbEnv;
      go = mkEditor "go" profiles.go lldbEnv;
      web = mkEditor "web" profiles.web lldbEnv;
      fun = mkEditor "fun" profiles.fun lldbEnv;
    };
  in {
    default = editors.full;

    inherit
      (editors)
      minimal
      python
      cxx
      rust
      go
      web
      fun
      ;

    cachix = pkgs.buildEnv {
      name = "cachix";
      paths = [editors.full];
    };
  }
