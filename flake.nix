{
  description = "Nix Flake package for my blog";
  inputs.nixpkgs.url = "nixpkgs/nixos-23.11";
  inputs.matejascv.url = "github:/MatejaMaric/cv";
  inputs.matejascv.inputs.nixpkgs.follows = "nixpkgs";
  outputs = { self, nixpkgs, matejascv }:
    let
      pkgName = "matejasblog";
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ matejascv.overlays.default ];
      });
      drv = {stdenv, hugo, matejascv}: stdenv.mkDerivation {
        name = pkgName;
        src = ./.;
        nativeBuildInputs = [ hugo ];
        buildPhase = ''
          hugo
        '';
        installPhase = ''
          mkdir -p $out/var/www
          cp -r public $out/var/www/matejamaric.com
          cp ${matejascv} $out/var/www/matejamaric.com/cv.pdf
        '';
      };
    in
    {
      overlays.default = (final: prev: {
        ${pkgName} = prev.callPackage drv { inherit matejascv; };
      });
      packages = forAllSystems (system: {
        ${pkgName} = nixpkgsFor.${system}.callPackage drv {};
        default = nixpkgsFor.${system}.callPackage drv {};
      });
      devShells = forAllSystems (system: {
        default = nixpkgsFor.${system}.mkShell {
          buildInputs = with nixpkgsFor.${system}; [ git rsync hugo ];
        };
      });
    };
}
