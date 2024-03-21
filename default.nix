{ pkgs ? import <nixpkgs> {}}:

pkgs.mkShell {
  packages = [
   pkgs.age
   pkgs.cloudflared
   pkgs.fluxcd
   pkgs.helmfile
   pkgs.jq
   pkgs.kubeconform
   pkgs.kustomize
   pkgs.moreutils
   pkgs.sops
   pkgs.stern
   pkgs.yq-go
   pkgs.envsubst
  ];
}
