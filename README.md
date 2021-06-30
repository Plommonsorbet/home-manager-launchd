# Home Manager Launchd

The launchd module is copied from the  [nix-darwin](https://github.com/LnL7/nix-darwin/) repo and slightly modified and dumped into a flake.

note: Currently it does not automatically update on rebuild, so you'll need to start it manually load it in via launchctl or log out/in.

## Docs

Since this is just copied from the nix-darwin repo and none of the options modified you can just use the [manual](https://daiderd.com/nix-darwin/manual/index.html#opt-environment.userLaunchAgents).


## Basic Flake example
```nix
{
  description = "Example Home Manager Launchd Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-20.09-darwin";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    hm-launchd.url = "github:Plommonsorbet/home-manager-launchd";

    home-manager = {
      url = "github:nix-community/home-manager/release-20.09";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = inputs@{ self, darwin, nixpkgs, home-manager, hm-launchd }: {
    darwinConfigurations."my-macos-configuration" = darwin.lib.darwinSystem {
      modules = [
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.my-username = {
            imports = [ hm-launchd.homeManager.launchd ];

	    # Example emacs daemon as launchd agent inside of home-manager.
            launchd.user.agents.emacs = {
              serviceConfig.ProgramArguments =
                [ "${pkgs.emacs}/bin/emacsclient" "--fg-daemon" ];
              serviceConfig.RunAtLoad = true;
            };
          };
        }
      ];
    };
  };
}
```

# TODO

- Add System activation Script
