{ pkgs, self }:

let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (lib.options) mkOption;
  inherit (lib) types;

  nixd.nixos = "(import <nixpkgs/nixos> { }).options";

  nixos =
    (import "${pkgs.path}/nixos/lib/eval-config.nix" {
      system = null;
      modules = [
        self.nixosModules.default
        {
          nixpkgs.hostPlatform = system;
          boot.loader.grub.enable = false;
          fileSystems."/" = {
            device = "none";
            fsType = "tmpfs";
          };
          system.stateVersion = "26.05";

          programs.hermes = {
            enable = true;
            profile = "rust";
            defaultEditor = true;
            inherit nixd;
          };
        }
      ];
    }).config;

  # the options home-manager would provide, so the module can be checked
  # without a home-manager input
  home =
    (lib.modules.evalModules {
      specialArgs = { inherit pkgs; };
      modules = [
        self.homeModules.default
        {
          options.home = {
            packages = mkOption {
              type = types.listOf types.package;
              default = [ ];
            };
            sessionVariables = mkOption {
              type = types.attrsOf types.str;
              default = { };
            };
          };
        }
        { programs.hermes.enable = true; }
      ];
    }).config;

  editorIn = packages: lib.lists.any (p: p.name == nixos.programs.hermes.package.name) packages;

  # starts the editor on an empty home, opens a file of each filetype and
  # fails on any error message
  startup =
    profile:
    pkgs.runCommandLocal "hermes-startup-${profile}"
      { nativeBuildInputs = [ self.packages.${system}.${profile} ]; }
      ''
        export HOME=$TMPDIR
        cd $TMPDIR
        nvim --headless -c "luafile ${./startup.lua}" </dev/null
        touch $out
      '';
in

{
  formatting = self.formatter.${system}.check self;

  # the committed lua is what make builds from the fennel
  fennel-sync =
    pkgs.runCommandLocal "hermes-fennel-sync"
      {
        nativeBuildInputs = [
          pkgs.gnumake
          pkgs.luajitPackages.fennel
        ];
      }
      ''
        cp -r --no-preserve=mode ${self} src
        cd src
        make -B -s
        diff -r ${self} .
        touch $out
      '';

  startup-minimal = startup "minimal";
  startup-full = startup "full";

  modules =
    assert lib.asserts.assertMsg (editorIn nixos.environment.systemPackages)
      "nixos: editor not installed";
    assert lib.asserts.assertMsg (nixos.environment.variables.EDITOR == "nvim") "nixos: EDITOR not set";
    assert lib.asserts.assertMsg (lib.strings.hasInfix nixd.nixos (
      nixos.programs.hermes.package.luaRcContent or ""
    )) "nixos: nixd expression not passed to the editor";
    assert lib.asserts.assertMsg (builtins.length home.home.packages == 1) "home: editor not installed";
    assert lib.asserts.assertMsg (
      !(home.home.sessionVariables ? EDITOR)
    ) "home: EDITOR set without defaultEditor";
    pkgs.runCommandLocal "hermes-modules" { } "touch $out";
}
