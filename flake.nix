{
  description = "NixOS configuration";

  nixConfig = {

    # Define extra cache locations to avoid building certain software locally
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      "https://cosmic.cachix.org/"
    ];
    
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
    ];
    
  };

  inputs = {
  
    # Nixpkgs
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05"; #stable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; #unstable

    # Home manager
    #
    # If I use the HM flakes setup in the next section, I believe this can be
    # deleted, but will need to test.
    home-manager = {
      url = "github:nix-community/home-manager";
      # url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland window manager
    hyprland-wm = {
      url = "github:hyprwm/Hyprland";
    };

    # COSMIC desktop
    cosmic-de.url = "github:lilyinstarlight/nixos-cosmic";

    apple-silicon = {
      url = "github:oliverbestmann/nixos-apple-silicon";
    };

    # Home Manager User Flakes
    #
    # Commented out until I figure out how to do multi-host in the user flakes.
    # I think it's as simple as the way I have been doing it, because HM is
    # standalone in this configuration, so I would just call, e.g.,
    # home-manager switch --flake ~/.config/nixconfig-users/user-cbl/#wren,
    # as usual.

    # cbl
    user-cbl = {
      # url = "git+https://git.crawfordlong.com/crawfordlong/user-cbl.git?ref=trunk";
      url = "git+ssh://git@git.crawfordlong.com:2022/crawfordlong/user-cbl.git?ref=trunk";
      # type = "git+ssh://git@git.crawfordlong.com:2022/";
      # owner = "crawfordlong";
      # repo = "user-cbl";
      # ref = "trunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # zen browser - including aarch64 build
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # ghostty terminal emulator dev flake
    # ghostty.url = "github:ghostty-org/ghostty";

    # porter
    # user-porter = {
    #   url = "http://git.crawfordlong.com/crawfordlong/user-porter.git";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # kari
    # user-kari = {
    #   url = "http://git.crawfordlong.com/crawfordlong/user-kari.git";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Other flakes
    nix-colors.url = "github:misterio77/nix-colors";
    # nix-colors-adapters.url = "gitlab:vfosnar/nix-colors-adapters"; # tool to apply nix-colors to some apps
    nix-colors-adapters.url = "github:crawfordlong/nix-colors-adapters"; # tool to apply nix-colors to some apps
    # stylix.url = "github:danth/stylix";

  };

  outputs = {
    self,
    apple-silicon,
    cosmic-de,
    nixpkgs,
    home-manager,
    nix-colors,
    nix-colors-adapters,
    nixos-aarch64-widevine,
    zen-browser,
    ... }
  @ inputs:
    let
      inherit (self) outputs;
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {

      packages = forAllSystems (system: import ./pkgs { inherit system nixpkgs; });
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

      overlays = import ./overlays { inherit inputs; };
      nixosModules = import ./modules/nixos;

      homeManagerModules = import ./modules/home-manager;

      nixosConfigurations = {

        indra = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs apple-silicon; };
          modules = [
            ./config/indra/default.nix
          ];
        };

        brahma = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            cosmic-de.nixosModules.default
            ./config/brahma/default.nix
          ];
        };

      homeConfigurations = {

        "cbl@wren" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          extraSpecialArgs = { inherit inputs outputs nix-colors nix-colors-adapters zen-browser; };
          modules = [
            ./users/cbl/wren.nix
          ];
        };

        "cbl@hornbill" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs nix-colors nix-colors-adapters; };
          modules = [
            ./users/cbl/hornbill.nix
          ];
        };

        "cbl@penguin" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./users/cbl/penguin.nix
          ];
        };

        "porter" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./users/porter/home.nix
          ];
        };

      };
    };
}
