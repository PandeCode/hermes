self: let
  inherit (self.inputs) nixpkgs;
in
  system: {
    default = let
      pkgs = nixpkgs.legacyPackages.${system};
    in
      nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with pkgs; [
          nh
          alejandra
          statix
          deadnix
          nixd
          nix-init
          nix-index
          nix-fast-build

          (luajit.withPackages (p:
            with p; [
              fennel
              readline
            ]))

          fnlfmt
          fennel-ls

          emmylua-ls
          emmylua-check

          inotify-tools
        ];
      };

    # pre-commit = nixpkgs.legacyPackages.${system}.mkShell {
    #   inherit (self.checks.${system}.pre-commit-check) shellHook;
    #   buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
    # };
  }
