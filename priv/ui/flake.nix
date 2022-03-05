{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = {self, nixpkgs}:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;
        npkgs = pkgs.nodePackages;
    in {
      defaultPackage.x86_64-linux = pkgs.hello;

      devShell.x86_64-linux =
        pkgs.mkShell {
          buildInputs = [

            pkgs.nodejs-17_x

            npkgs.typescript
            npkgs.node-gyp
            npkgs.serve

          ];
        };
    };
}
