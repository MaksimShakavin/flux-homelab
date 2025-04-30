{
  description = "Basic workstation dependencies";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    talhelper.url = "github:budimanjojo/talhelper";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, talhelper, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.age
            pkgs.cloudflared
            pkgs.helmfile
            pkgs.jq
            pkgs.kustomize
            pkgs.moreutils
            pkgs.sops
            pkgs.stern
            pkgs.yq-go
            pkgs.envsubst
            pkgs.minijinja
            pkgs._1password-cli
            pkgs.cilium-cli
            pkgs.minio-client
            talhelper.packages.${system}.default
          ];
        };
      });
}
