{
  description = "AlgoTeX flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    tuda-logo = {
      url = "https://upload.wikimedia.org/wikipedia/de/2/24/TU_Darmstadt_Logo.svg";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      tuda-logo,
    }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # minimal example shell for using algotex

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            buildInputs = [
              pkgs.python313Packages.pygments
              pkgs.latex_with_algotex
            ];
          };
        }
      );

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          # algotex and logo only
          algotex = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
            name = "algotex";
            src = ./.;
            passthru = {
              pkgs = [ finalAttrs.finalPackage ];
              tlType = "run";
              tlDeps = with pkgs.texlive; [ latex ];
            };
            nativeBuildInputs = with pkgs; [ librsvg ];
            installPhase = ''
              runHook preInstall

              # copy algotex files
              algotex_path=$out/tex/latex/algotex
              mkdir -p $algotex_path
              cp $src/tex/* $algotex_path/

              # build tuda logo
              logo_path=$out/tex/latex/local
              mkdir -p $logo_path
              rsvg-convert -f pdf -o $logo_path/tuda_logo.pdf ${tuda-logo}

              runHook postInstall
            '';
            dontConfigure = true;
            dontBuild = true;
          });

          # full texlive distribution with algotex and the logo file
          default = pkgs.texlive.combine {
            inherit (pkgs.texlive) scheme-full;
            inherit (self.packages.${system}) algotex;
          };
        }
      );
    };
}
