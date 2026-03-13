{
  description = "Hopefully my last iteration on my editor";

  nixConfig = {
    trusted-users = ["root" "shawn"];
    experimental-features = ["nix-command" "flakes" "pipe-operators"];
    accept-flake-config = true;
    show-trace = true;
    auto-optimise-store = true;

    # substituters = ["https://aseipp-nix-cache.freetls.fastly.net"];

    extra-substituters = [
      "https://charon.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "charon.cachix.org-1:epdetEs1ll8oi8DT8OG2jEA4whj3FDbqgPFvapEPbY8="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    systems = {
      x86_64-linux = "x86_64-linux";
      # aarch64-linux = "aarch64-linux";
      # x86_64-darwin = "x86_64-darwin";
      # aarch64-darwin = "aarch64-darwin";
    };
    supportedSystems = builtins.attrNames systems;
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    extras =
      self
      // {
        overlays = (import ./nix/overlays.nix) inputs;
      };
  in {
    nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

    # nixosConfigurations = (import ./nix/nixosConfigurations.nix) extras;
    # homeConfigurations = (import ./nix/homeConfigurations.nix) extras;
    # checks = forAllSystems ((import ./nix/checks.nix) extras);
    devShells = forAllSystems ((import ./nix/devShells.nix) extras);
    packages = forAllSystems ((import ./nix/packages.nix) extras);
  };
}
