{
  description = "Desktop shell for Caelestia dots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.caelestia-shell.follows = "";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    forAllSystems = fn:
      nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux (
        system: fn nixpkgs.legacyPackages.${system}
      );
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    packages = forAllSystems (pkgs: rec {
      caelestia-shell = pkgs.callPackage ./default.nix {
        rev = self.rev or self.dirtyRev;
        quickshell = inputs.quickshell.packages.${pkgs.system}.default.override {
          withX11 = false;
          withI3 = false;
        };
        caelestia-cli = inputs.caelestia-cli.packages.${pkgs.system}.default;
      };
      with-cli = caelestia-shell.override {withCli = true;};
      default = caelestia-shell;
    });

    devShells = forAllSystems (pkgs: {
      default = let
        shell = self.packages.${pkgs.system}.caelestia-shell;
      in
        pkgs.mkShellNoCC {
          inputsFrom = [shell];
          packages = with pkgs; [material-symbols nerd-fonts.jetbrains-mono];
          CAELESTIA_BD_PATH = "${shell}/bin/beat_detector";
        };
    });
  };
}
