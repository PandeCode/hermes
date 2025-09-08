Ship with neovide

make shell.nix(s) to have different templetes ready for different environments

aspell

matlab

Rust

Go

Web

C/Cpp

Shaders (glsl_analyzer, clang-format)

```nix
    extraPackages =
      (with pkgs.vimPlugins.nvim-treesitter-parsers; [asm bash c comment cpp csv fish git_config git_rebase gitattributes gitcommit gitignore glsl heex html javascript json json5 kdl latex lua luadoc luau make markdown markdown_inline nix nu powershell python query rust tsx typescript vim vimdoc scss graphql fennel gdshader gdscript racket])
      ++ (with pkgs; [
        (pkgs.python3.withPackages (python-pkgs:
          with python-pkgs; [
            python-lsp-server
            python-lsp-ruff
            python-lsp-black
            pyls-memestra
            pylsp-rope
          ]))

        (aspellWithDicts
          (dicts: with dicts; [de en en-computers en-science es fr la]))

        mpls

        # (import ../../derivations/codelldb.nix {inherit pkgs;})
        # (import ../../derivations/cpptools.nix {inherit pkgs;})

        haskell-language-server
        tex-fmt

        chafa
        dwt1-shell-color-scripts
        pokemon-colorscripts-mac

        ghostscript_headless

        # Language Servers
        # basedpyright
        # emmet-ls
        # glsl_analyzer
        # gopls
        lua-language-server
        # neocmakelsp
        nixd
        clang-tools
        nil
        nodePackages.bash-language-server
        pylyzer
        tailwindcss-language-server
        texlab
        # vim-language-server
        vscode-langservers-extracted
        yaml-language-server

        # Formatters
        alejandra
        black
        nodePackages.prettier
        prettierd
        shfmt
        stylua

        # Linters
        markdownlint-cli

        # Utilities
        ctags
        lazygit
        ra-multiplex
        tree-sitter
        xxd
      ]);
```
