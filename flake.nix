{
  description = "Simple Task Manager";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      pkgs = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      packages = forAllSystems (system: {
        default = pkgs.${system}.stdenv.mkDerivation rec {
          pname = "stm";
          version = "0.1.0";
          src = ./.;

          buildInputs = with pkgs.${system}; [
            nushell
            gum
          ];

          installPhase = ''
            mkdir -p $out/bin
            cp ${./stm.nu} $out/bin/${pname}
          '';
        };
      });

      devShells = forAllSystems (system: {
        default = pkgs.${system}.mkShell {
          buildInputs = with pkgs.${system}; [
            nushell
            gum
          ];
        };
      });
    };
}
