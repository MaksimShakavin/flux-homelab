{
  description = "A basic flake with a shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    talhelper.url = "github:budimanjojo/talhelper";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, talhelper, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.age
            pkgs.cloudflared
            pkgs.helmfile
            pkgs.jq
            pkgs.kubeconform
            pkgs.kustomize
            pkgs.moreutils
            pkgs.sops
            pkgs.stern
            pkgs.yq-go
            pkgs.envsubst
            talhelper.packages.${system}.default
          ];
        };
      });
}
