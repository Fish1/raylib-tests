{
	description = "test1";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		utils.url = "github:numtide/flake-utils";
	};

	outputs = { nixpkgs, utils, ... }:
	utils.lib.eachDefaultSystem(system:
		let
			pkgs = import nixpkgs {
				inherit system;
			};
		in {
			devShells.default = pkgs.mkShell {
				buildInputs = [
					pkgs.zig
					pkgs.zls
					pkgs.raylib
					
					pkgs.xorg.libXrender
					pkgs.xorg.libXrandr
					pkgs.xorg.libXinerama
					pkgs.xorg.libXi
					pkgs.xorg.libXfixes
					pkgs.xorg.libXext
					pkgs.xorg.libXcursor

					pkgs.lmms
				];

				LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [pkgs.alsa-lib];
			};
		}
	);
}
