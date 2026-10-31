inputs:

let
  inherit (inputs)
    nixbuilds
    nixpkgs
    nixutils
    self
    ;

  # gdb and lldb in the toolsets only build on linux. unfree is allowed for
  # vim-wordmotion
  forAllPkgs =
    fn:
    nixutils.lib.forSystems [ "x86_64-linux" "aarch64-linux" ] (
      system:
      fn (
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ nixbuilds.overlays.default ];
        }
      )
    );

  profiles = [
    "minimal"
    "python"
    "cxx"
    "rust"
    "zig"
    "go"
    "web"
    "fun"
    "full"
  ];

  # the lua that make builds from the fennel, found the way the Makefile does
  compiledLua =
    let
      inherit (nixpkgs) lib;
      fennelIn =
        dir:
        lib.lists.optionals (builtins.pathExists ../${dir}) (
          lib.lists.filter (lib.strings.hasSuffix ".fnl") (
            map (lib.path.removePrefix ../.) (lib.filesystem.listFilesRecursive ../${dir})
          )
        );
    in
    map (file: lib.strings.removePrefix "./" (lib.strings.removeSuffix ".fnl" file) + ".lua") (
      [ "init.fnl" ]
      ++ lib.lists.concatMap fennelIn [
        "plugin"
        "ftplugin"
        "after/plugin"
        "after/ftplugin"
      ]
    );
in

{
  packages = forAllPkgs (
    pkgs:
    let
      editor = import ../nix/editor.nix {
        inherit pkgs;
        neovim = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
        nixpkgs-src = nixpkgs.outPath;
        src = self;
      };
    in
    nixpkgs.lib.attrsets.genAttrs profiles (profile: editor.override { inherit profile; })
    // {
      default = editor;
    }
  );

  nixosModules.default = import ../nix/module.nix {
    inherit self;
    class = "nixos";
  };

  homeModules.default = import ../nix/module.nix {
    inherit self;
    class = "homeManager";
  };

  checks = forAllPkgs (pkgs: import ./checks.nix { inherit pkgs self; });

  formatter = forAllPkgs (
    pkgs:
    pkgs.treefmt.withConfig [
      nixutils.lib.treefmtModule
      # the lua that make builds from the fennel
      { settings.excludes = compiledLua; }
    ]
  );

  devShells = forAllPkgs (pkgs: {
    default = pkgs.mkShellNoCC {
      packages = with pkgs; [
        (luajit.withPackages (
          p: with p; [
            fennel
            readline
          ]
        ))
        fnlfmt
        fennel-ls
        emmylua-ls
        emmylua-check
        inotify-tools
        self.formatter.${stdenv.hostPlatform.system}
        self.packages.${stdenv.hostPlatform.system}.default
      ];
    };
  });
}
