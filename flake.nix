{
  description = "A Nix-flake-based Go development environment with pre-commit shell hook";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix2container.url = "github:nlewo/nix2container";
  };

  outputs = inputs @ {
    self,
    flake-parts,
    nix2container,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # bring in git-hooks.nix's flake module for easy pre-commit setup
      imports = [inputs.git-hooks-nix.flakeModule];

      perSystem = {
        config,
        pkgs,
        lib,
        system,
        self',
        ...
      }: let
        # Pick a Go toolchain (falls back gracefully if attr name changes)
        goPkg = pkgs.go;
        # Common Go dev tools
        goTools = with pkgs; [
          goPkg
          gopls
          gotools
          golangci-lint
          delve
        ];
        goHello = pkgs.buildGoModule rec {
          pname = "go-hello";
          version = "0.1.0";
          src = ./.;
          doCheck = false;
          vendorHash = "sha256-1/Ly1RohO1fJTs4S5l0dngkWcI1uNZ4hseOzSmuAr1w=";
          subPackages = ["."];
        };
        inherit (inputs.nix2container.packages.${system}.nix2container) buildImage;
        goHelloRoot = pkgs.runCommand "go-hello-root" {} ''
          mkdir -p $out/bin
          ln -s ${goHello}/bin/go-hello $out/bin/go-hello
        '';
        containerImage =
          buildImage {
            name = "go-hello";
            tag = "latest";
            copyToRoot = [goHelloRoot];
            config = {
              Cmd = ["/bin/go-hello"];
              ExposedPorts = {
                "8080/tcp" = {};
              };
            };
          };
      in {
        # Configure pre-commit via git-hooks.nix
        pre-commit.settings = {
          # Keep universally-helpful text hooks
          hooks = {
            end-of-file-fixer.enable = true;
            # Custom Go hooks via "system" language
            go-fmt = {
              enable = true;
              name = "go fmt";
              entry = "${goPkg}/bin/gofmt -l -w";
              language = "system";
              files = "\\.go$";
            };
            golangci-lint = {
              enable = true;
              name = "golangci-lint";
              entry = "${pkgs.golangci-lint}/bin/golangci-lint run --fix=false";
              language = "system";
              files = "\\.go$";
            };
          };

          # Make sure hooks have the right tools available
          enabledPackages = goTools;
        };
        devShells.default = pkgs.mkShell {
          name = "go-dev";

          packages =
            goTools
            ++ config.pre-commit.settings.enabledPackages;

          # Install the pre-commit hook on shell entry
          shellHook = config.pre-commit.installationScript;
        };

        packages = {
          default = goHello;
          go-hello = goHello;
          container = containerImage;
        };

        apps.default = {
          type = "app";
          program = "${goHello}/bin/go-hello";
        };
      };

      flake = {};
    };
}
