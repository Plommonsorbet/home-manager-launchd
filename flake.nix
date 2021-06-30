{
  description = "Launchd Home Manager Module";

  outputs = { self, nixpkgs }: {
    hmModules.launchd = import ./modules/launchd/;
  };

}
