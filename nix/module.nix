# the same module for nixos and home-manager; `class` picks where packages
# and variables go
{ self, class }:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib) types;

  cfg = config.programs.hermes;

  editor = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
in

{
  options.programs.hermes = {
    enable = mkEnableOption "hermes, my neovim";

    profile = mkOption {
      type = types.enum [
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
      default = "full";
      description = "Which language tools come with the editor.";
    };

    nixd = {
      nixos = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = ''(builtins.getFlake "/home/me/dotnix").nixosConfigurations.laptop.options'';
        description = "Nix expression nixd evaluates for NixOS option completion.";
      };

      home-manager = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Nix expression nixd evaluates for home-manager option completion.";
      };
    };

    package = mkOption {
      type = types.package;
      default = editor.override {
        inherit (cfg) profile;
        nixd = lib.attrsets.filterAttrs (_: v: v != null) cfg.nixd;
      };
      defaultText = lib.literalExpression "hermes built from profile and nixd";
      description = "The editor package.";
    };

    defaultEditor = mkEnableOption "hermes as EDITOR";
  };

  config = mkIf cfg.enable (mkMerge [
    (lib.optionalAttrs (class == "nixos") {
      environment.systemPackages = [ cfg.package ];
      environment.variables.EDITOR = mkIf cfg.defaultEditor "nvim";
    })

    (lib.optionalAttrs (class == "homeManager") {
      home.packages = [ cfg.package ];
      home.sessionVariables.EDITOR = mkIf cfg.defaultEditor "nvim";
    })
  ]);
}
