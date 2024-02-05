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
      packages = forAllSystems (system:
      {
        script = pkgs.${system}.writeScript "stm" (builtins.readFile ./stm.nu);
        default = pkgs.${system}.writeScriptBin "stm" ''
          #!/usr/bin/env nu

          use ${./stm.nu} stm
          $env.PATH = $env.PATH ++ [${pkgs.${system}.gum}/bin]
          alias main = stm
          echo $env.PATH
        '';
      });

      homeManagerModules.default = import ./hm-module.nix self;

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
