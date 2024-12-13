{
  description = "zig-tracy development environment";

  inputs = {
    zig-source = {
      url = "https://ziglang.org/builds/zig-linux-x86_64-0.14.0-dev.2435+7575f2121.tar.xz";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    zig-source
  }:
  let
    default_system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${default_system};
    zig_0_14_0_rc = pkgs.stdenv.mkDerivation rec {
      pname = "zig";
      version = "0.14.0-dev.2435+7575f2121";
      src = zig-source.outPath;

      installPhase = ''
        mkdir -p "$out/bin"
        cp zig "$out/bin"
        cp -r lib "$out"
        cp -r doc "$out"
      '';

      meta = with pkgs.lib; {
        homepage = "https://ziglang.org/";
        description = "General-purpose programming language and toolchain for maintaining robust, optimal, and reusable software";
        license = licenses.mit;
        platforms = platforms.unix;
      };
    };
  in {
    devShell.${default_system} = pkgs.mkShell {
      nativeBuildInputs = [
        zig_0_14_0_rc
        pkgs.lldb_16
      ];
    };
  };
}

