# Copyright (c) 2025 PandeCode
# Licensed under the MIT license
{
  description = "hermes - neovim config";

  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operators"
    ];
    accept-flake-config = true;
    show-trace = true;

    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://charon.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "charon.cachix.org-1:epdetEs1ll8oi8DT8OG2jEA4whj3FDbqgPFvapEPbY8="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # plugins-hover-nvim = {
    #   url = "github:PandeCode/hover.nvim";
    #   flake = false;
    # };

    plugins-snacks-nvim = {
      url = "github:PandeCode/snacks.nvim";
      flake = false;
    };

    plugins-vlime = {
      url = "github:vlime/vlime";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (inputs.nixCats) utils;
    luaPath = ./.;
    forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
    extra_pkg_config = {
      # allowUnfree = true;
    };

    # see :help nixCats.flake.outputs.overlays
    dependencyOverlays =
      # (import ./overlays inputs) ++
      [
        # This overlay grabs all the inputs named in the format
        # `plugins-<pluginName>`
        # Once we add this overlay to our nixpkgs, we are able to
        # use `pkgs.neoVimPlugins`, which is a set of our plugins.
        (utils.standardPluginOverlay inputs)
        # add any other flake overlays here.

        # when other people mess up their overlays by wrapping them with system,
        # you may instead call this function on their overlay.
        # it will check if it has the system in the set, and if so return the desired overlay
        # (utils.fixSystemizedOverlay inputs.codeium.overlays
        #   (system: inputs.codeium.overlays.${system}.default)
        # )
      ];

    categoryDefinitions = {
      pkgs,
      # settings,
      # categories,
      # extra,
      # name,
      # mkPlugin,
      ...
    }
    # @ packageDef
    : {
      lspsAndRuntimeDeps = with pkgs; {
        general = [
          # General tools
          universal-ctags
          ripgrep
          fd
          proselint

          prettierd

          emmylua-ls
          emmylua-check
          emmylua-doc-cli

          ccls

          sbcl

          (python3.withPackages (p: with p; [black]))
          ruff
          pyright

          lua-language-server

          nixd
          statix
          stylua
          alejandra
          deadnix
        ];
        extras = [
          bun
          vscode-langservers-extracted
          typescript-language-server
          eslint
          tailwindcss-language-server
          emmet-ls

          rust-analyzer
          bash-language-server
          systemd-lsp
          neocmakelsp

          (callPackage ./nix/codelldb.nix {})
          (callPackage ./nix/cpptools.nix {})

          go
          gopls
          gotools
          go-tools
          clang-tools
          neocmakelsp
          cmake-format
          cmake-lint
        ];
      };

      # Plugins that load automatically at startup
      startupPlugins = with pkgs.vimPlugins; {
        general = {
          always = [
            # Core plugins
            lze
            lzextras
            vim-repeat
            plenary-nvim
            rainbow-delimiters-nvim

            # Editor enhancement
            vim-visual-multi
            vim-wordmotion
            vim-sleuth

            # UI and status
            vim-wakatime
            nvim-web-devicons
            lualine-nvim
            bufferline-nvim

            # File management
            oil-nvim

            # LSP and formatting
            none-ls-nvim
            nvim-lspconfig

            # Git integration
            gitsigns-nvim
            vim-fugitive
            vim-rhubarb

            # Completion
            luasnip
            cmp-cmdline
            blink-cmp
            blink-compat
            colorful-menu-nvim
            lspkind-nvim
            friendly-snippets

            # UI enhancements
            noice-nvim
            mini-nvim
            neoscroll-nvim

            pkgs.neovimPlugins.snacks-nvim

            # already lazy
            haskell-tools-nvim
          ];
        };
      };

      # Plugins that can be lazy loaded
      optionalPlugins = with pkgs.vimPlugins; {
        general = {
          lazy = [
            cord-nvim

            pkgs.neovimPlugins.vlime
            parinfer-rust

            # Debugging
            nvim-nio
            nvim-dap
            nvim-dap-ui
            nvim-dap-virtual-text
            nvim-dap-go

            refactoring-nvim

            # Treesitter
            nvim-treesitter-textobjects
            nvim-treesitter.withAllGrammars
            # (nvim-treesitter.withPlugins (
            #   plugins: with plugins; [
            #     nix
            #     lua
            #   ]
            # ))

            typescript-tools-nvim

            # Web development
            markdown-preview-nvim

            # Additional tools
            codecompanion-nvim
            dropbar-nvim
            fidget-nvim
            undotree
            vim-startuptime
            # avante-nvim
            overseer-nvim
            # hover-nvim
          ];
        };
      };

      # LD_LIBRARY_PATH
      sharedLibraries = {
        general = [
          # <- this would be included if any of the subcategories of general are
          # libgit2
        ];
      };

      # environmentVariables:
      # this section is for environmentVariables that should be available
      # at RUN TIME for plugins. Will be available to path within neovim terminal
      environmentVariables = {
        test = {
          default = {
            CATTESTVARDEFAULT = "It worked!";
          };
          subtest1 = {
            CATTESTVAR = "It worked!";
          };
          subtest2 = {
            CATTESTVAR3 = "It didn't work!";
          };
        };
      };

      # If you know what these are, you can provide custom ones by category here.
      # If you dont, check this link out:
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
      extraWrapperArgs = {
        test = [
          ''--set CATTESTVAR2 "It worked again!"''
        ];
      };

      # lists of the functions you would have passed to
      # python.withPackages or lua.withPackages
      # do not forget to set `hosts.python3.enable` in package settings

      # get the path to this python environment
      # in your lua config via
      # vim.g.python3_host_prog
      # or run from nvim terminal via :!<packagename>-python3
      python3.libraries = {
        test = _: [];
      };
      # populates $LUA_PATH and $LUA_CPATH
      extraLuaPackages = {
        general = [(_: [])];
      };

      # see :help nixCats.flake.outputs.categoryDefinitions.default_values
      # this will enable test.default and debug.default
      # if any subcategory of test or debug is enabled
      # WARNING: use of categories argument in this set will cause infinite recursion
      # The categories argument of this function is the FINAL value.
      # You may use it in any of the other sets.
      extraCats = {
        test = [
          [
            "test"
            "default"
          ]
        ];
      };
    };

    # packageDefinitions:

    # Now build a package with specific categories from above
    # All categories you wish to include must be marked true,
    # but false may be omitted.
    # This entire set is also passed to nixCats for querying within the lua.
    # It is directly translated to a Lua table, and a get function is defined.
    # The get function is to prevent errors when querying subcategories.

    # see :help nixCats.flake.outputs.packageDefinitions
    packageDefinitions = {
      # Single unified nvim package with all language support
      nvim = {
        pkgs,
        name,
        ...
      } @ misc: {
        # these also recieve our pkgs variable
        # see :help nixCats.flake.outputs.packageDefinitions
        settings = {
          suffix-path = true;
          suffix-LD = true;
          aliases = [];
          wrapRc = true;
          configDirName = "nixCats-nvim";
          # neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
          hosts = {
            python3.enable = true;
            node.enable = true;
            neovide = {
              enable = true;
              path = {
                value = "${pkgs.neovide}/bin/neovide";
                args = [
                  "--add-flags"
                  "--neovim-bin ${name}"
                ];
              };
            };
            neo = {
              enable = true;
              path = {
                value = "${pkgs.bash}/bin/bash";
                args = [
                  "--add-flags"
                  ''
                    -c '${pkgs.fzf}/bin/fzf | xargs -I {} ${pkgs.neovide}/bin/neovide {} --neovim-bin ${name} 2>&1 > /dev/null & disown'
                  ''
                ];
              };
            };
          };
        };
        # enable the categories you want from categoryDefinitions
        categories = {
          general = true;
          ai = true;
          lspDebugMode = false;
        };
        extra = {
          # to keep the categories table from being filled with non category things that you want to pass
          # there is also an extra table you can use to pass extra stuff.
          # but you can pass all the same stuff in any of these sets and access it in lua
          vlimePath = "${pkgs.neovimPlugins.vlime}";
          nixdExtras = {
            nixpkgs = ''import ${pkgs.path} {}'';
            # or inherit nixpkgs;
          };
        };
      };

      regularCats = {pkgs, ...} @ misc: {
        settings = {
          suffix-path = true;
          suffix-LD = true;
          # IMPURE PACKAGE: normal config reload
          # include same categories as main config,
          # will load from vim.fn.stdpath('config')
          wrapRc = false;
          # or tell it some other place to load
          # unwrappedCfgPath = "/some/path/to/your/config";

          # configDirName: will now look for nixCats-nvim within .config and .local and others
          # this can be changed so that you can choose which ones share data folders for auths
          # :h $NVIM_APPNAME
          configDirName = "nixCats-nvim";

          aliases = ["testCat"];

          # If you wanted nightly, uncomment this, and the flake input.
          # neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
          # Probably add the cache stuff they recommend too.
        };
        categories = {
          general = true;
          test = true;
          lspDebugMode = false;
        };
        extra = {
          # nixCats.extra("path.to.val") will perform vim.tbl_get(nixCats.extra, "path" "to" "val")
          # this is different from the main nixCats("path.to.cat") in that
          # the main nixCats("path.to.cat") will report true if `path.to = true`
          # even though path.to.cat would be an indexing error in that case.
          # this is to mimic the concept of "subcategories" but may get in the way of just fetching values.
          nixdExtras = {
            nixpkgs = ''import ${pkgs.path} {}'';
            # or inherit nixpkgs;
          };
          # yes even tortured inputs work.
          theBestCat = "says meow!!";
          theWorstCat = {
            thing'1 = [
              "MEOW"
              '']]' ]=][=[HISSS]]"[[''
            ];
            thing2 = [
              {
                thing3 = [
                  "give"
                  "treat"
                ];
              }
              "I LOVE KEYBOARDS"
              (utils.mkLuaInline ''[[I am a]] .. [[ lua ]] .. type("value")'')
            ];
            thing4 = "couch is for scratching";
          };
        };
      };
    };

    defaultPackageName = "nvim";
    # I did not here, but you might want to create a package named nvim.
    # defaultPackageName is also passed to utils.mkNixosModules and utils.mkHomeModules
    # and it controls the name of the top level option set.
    # If you made a package named `nixCats` your default package as we did here,
    # the modules generated would be set at:
    # config.nixCats = {
    #   enable = true;
    #   packageNames = [ "nixCats" ]; # <- the packages you want installed
    #   <see :h nixCats.module for options>
    # }
    # In addition, every package exports its own module via passthru, and is overrideable.
    # so you can yourpackage.homeModule and then the namespace would be that packages name.
  in
    # you shouldnt need to change much past here, but you can if you wish.
    # but you should at least eventually try to figure out whats going on here!
    # see :help nixCats.flake.outputs.exports
    forEachSystem (
      system: let
        # and this will be our builder! it takes a name from our packageDefinitions as an argument, and builds an nvim.
        nixCatsBuilder =
          utils.baseBuilder luaPath {
            # we pass in the things to make a pkgs variable to build nvim with later
            inherit
              nixpkgs
              system
              dependencyOverlays
              extra_pkg_config
              ;
            # and also our categoryDefinitions and packageDefinitions
          }
          categoryDefinitions
          packageDefinitions;
        # call it with our defaultPackageName
        defaultPackage = nixCatsBuilder defaultPackageName;

        # this pkgs variable is just for using utils such as pkgs.mkShell
        # within this outputs set.
        pkgs = import nixpkgs {inherit system;};
        # The one used to build neovim is resolved inside the builder
        # and is passed to our categoryDefinitions and packageDefinitions
      in rec {
        # these outputs will be wrapped with ${system} by utils.eachSystem

        # this will generate a set of all the packages
        # in the packageDefinitions defined above
        # from the package we give it.
        # and additionally output the original as default.
        packages = utils.mkAllWithDefault defaultPackage;

        devShells = {
          default = pkgs.mkShell {
            name = defaultPackageName;
            packages = with pkgs; [
              (packages.default)
              statix
              deadnix
              alejandra
              stylua
            ];
            inputsFrom = [];
            shellHook = '''';
          };
        };
      }
    )
    // (
      let
        nixosModule = utils.mkNixosModules {
          moduleNamespace = [defaultPackageName];
          inherit
            defaultPackageName
            dependencyOverlays
            luaPath
            categoryDefinitions
            packageDefinitions
            extra_pkg_config
            nixpkgs
            ;
        };
        homeModule = utils.mkHomeModules {
          moduleNamespace = [defaultPackageName];
          inherit
            defaultPackageName
            dependencyOverlays
            luaPath
            categoryDefinitions
            packageDefinitions
            extra_pkg_config
            nixpkgs
            ;
        };
      in {
        # these outputs will be NOT wrapped with ${system}

        # this will make an overlay out of each of the packageDefinitions defined above
        # and set the default overlay to the one named here.
        overlays =
          utils.makeOverlays luaPath {
            inherit nixpkgs dependencyOverlays extra_pkg_config;
          }
          categoryDefinitions
          packageDefinitions
          defaultPackageName;

        nixosModules.default = nixosModule;
        homeModules.default = homeModule;

        inherit utils nixosModule homeModule;
        inherit (utils) templates;
      }
    );
}
