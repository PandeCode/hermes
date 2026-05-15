flake.nix

```nix
{
  description = "sample nixos config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nix-index-database,
    ...
    } @ inputs: let
      system = "x86_64-linux";
    in {
      nixosConfigurations = let
        mkConfig = modules:
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {inherit inputs;};
            modules = modules ++ [ ./configuration.nix ];
          };
      in {
        laptop = mkConfig [ ./laptop.nix ];
        desktop = mkConfig [ ./desktop.nix ];
        server = mkConfig [ ] ; # idk ngix or some docker bs
      };
    };
}
```
./configuration.nix
here i would put stuff that is really convient to have on all ur machines (shells, aliases, preferable terminal only stuff)

```nix
{pkgs, inputs, ...}:{
  imports = [ nix-index-database.nixosModules.nix-index ];
  programs.fish.enable = true;
  programs.nushell.enable = true;
  programs.nix-index-database.comma.enable = true;
}
```

./grapical.nix
```nix
{pkgs, inputs, ...}:{
  # whatever was here before
  imports = [inputs.zen-browser.homeModules.twilight];

  programs.zen-browser = {
    enable = true;
    # the home manager version has a bunch of cool shit you can use to make your browser Declarative
  };
  # other stuff
}
```

./laptop.nix
here, stuff pertaining to only my laptop, display server
```nix
{pkgs, inputs, ...}:{
  imports = [./grapical.nix]
}
```

./desktop.nix
here, stuff pertaining to only my desktop, different display server, steam (if you only game on ur desktop)
```nix
{pkgs, inputs, ...}:{
  imports = [./grapical.nix]
  hardware = {
    steam-hardware.enable = true;
  };
}
```
