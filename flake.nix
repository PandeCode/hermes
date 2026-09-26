{
  description = "Hopefully my last iteration on my editor";

  # lets people who use hermes download it instead of building it
  nixConfig = {
    extra-substituters = [
      "https://charon.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "charon.cachix.org-1:epdetEs1ll8oi8DT8OG2jEA4whj3FDbqgPFvapEPbY8="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs = inputs: import ./flake inputs;

  inputs = {
    # the shared nixpkgs pin
    nixpkgs.follows = "nixbuilds/nixpkgs";

    # my packages and the language toolsets
    nixbuilds = {
      type = "github";
      owner = "PandeCode";
      repo = "nixbuilds";
    };

    # my lib and the shared formatter config
    nixutils = {
      type = "github";
      owner = "PandeCode";
      repo = "nixutils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # neovim built from master
    neovim-nightly-overlay = {
      type = "github";
      owner = "nix-community";
      repo = "neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # common lisp plugin, not in nixpkgs
    vlime = {
      type = "github";
      owner = "vlime";
      repo = "vlime";
      flake = false;
    };
  };
}
