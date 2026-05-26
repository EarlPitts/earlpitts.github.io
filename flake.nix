{
  description = "Haskell flake with OpenGL stuff";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        haskellPackages = pkgs.haskellPackages;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with haskellPackages; [
            (ghcWithPackages (hp: [ hp.hakyll ]))
            cabal-install
            haskell-language-server
            hlint
            pkgs.mesa
            pkgs.freeglut
            pkgs.mesa_glu
            pkgs.zlib
            cabal-fmt
            # Add any system dependencies here
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.freeglut
            pkgs.mesa
            pkgs.mesa_glu
            pkgs.zlib
          ];
        };
      }
    );
}
