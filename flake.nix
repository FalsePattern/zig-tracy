{
  description = "zig-tracy development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";

    zls-flake.url = "github:zigtools/zls";
    zls-flake.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, zig-overlay, zls-flake }: let
    inherit (nixpkgs) lib;

    # flake-utils polyfill
    eachSystem = systems: fn:
      lib.foldl' (
        acc: system:
          lib.recursiveUpdate
          acc
          (lib.mapAttrs (_: value: {${system} = value;}) (fn system))
      ) {}
      systems;

    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
  in eachSystem systems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        zls = zls-flake.packages.${system}.zls;
        zig = zig-overlay.packages.${system}.master-2025-02-14;
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            zig
            zls
            pkgs.lldb_16
          ];
        };
      });
}

