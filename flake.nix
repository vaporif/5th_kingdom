{
  description = "shroom_shrooms - a Bevy game";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    fenix,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      rustToolchain = fenix.packages.${system}.stable.withComponents [
        "cargo"
        "clippy"
        "rustc"
        "rust-src"
        "rust-analyzer"
      ];

      darwinDeps = with pkgs;
        pkgs.lib.optionals stdenv.hostPlatform.isDarwin [
          apple-sdk
        ];

      linuxDeps = with pkgs;
        pkgs.lib.optionals stdenv.hostPlatform.isLinux [
          udev
          alsa-lib
          vulkan-loader

          # wayland
          libxkbcommon
          wayland

          # x11
          xorg.libX11
          xorg.libXcursor
          xorg.libXi
          xorg.libXrandr
        ];
    in {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          rustToolchain
          pkg-config
        ];

        buildInputs = darwinDeps ++ linuxDeps;

        shellHook =
          ''
            export RUST_LOG=info
          ''
          + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath linuxDeps}:$LD_LIBRARY_PATH"
          '';
      };
    });
}
