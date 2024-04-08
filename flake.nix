{
  description = "Nix Flake package for my blog";
  inputs.nixpkgs.url = "nixpkgs/nixos-23.11";
  outputs = { self, nixpkgs }:
    let
      pkgName = "matejasblog";
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
      drv = {stdenv, hugo, ...}: stdenv.mkDerivation {
        name = pkgName;
        src = ./.;
        buildInputs = [ hugo ];
        buildPhase = ''
          hugo
        '';
        installPhase = ''
          mkdir -p $out/var/www
          cp -r public $out/var/www/matejamaric.com
        '';
      };
    in
    {
      overlays.default = (final: prev: {
        matejasblog = prev.callPackage drv {};
      });
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in {
          ${pkgName} = drv pkgs;
          default = drv pkgs;
        }
      );
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ git rsync hugo ];
          };
        }
      );
    };
}
