{
  description = "A PyTorch-based thing that is definitely not a transformer";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a";
  };

  outputs = inputs @ { self, nixpkgs, flake-utils, ... }: 
  (flake-utils.lib.eachDefaultSystem (system: 
  let
  	pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    devShells = {
	default = pkgs.mkShellNoCC {
		packages = [ pkgs.ocamlPackages.cpdf pkgs.parallel ];
	};
    };
  }
  ));
}
