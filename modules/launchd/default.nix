{ config, lib, pkgs, ... }:

with import ./lib.nix { inherit lib; };
with lib;

let
  inherit (pkgs) stdenv;

  cfg = config.launchd;

  toLaunchAgent = name: value: {
    name = "/Library/LaunchAgents/${value.serviceConfig.Label}.plist";
    value.text = toPLIST value.serviceConfig;
  };

  launchdConfig = import ./launchd.nix;

  makeDrvBinPath = ps: concatMapStringsSep ":" (p: if isDerivation p then "${p}/bin" else p) ps;

  serviceOptions =
    { config, name, ... }:
    let

      cmd = config.command;
      env = config.environment // optionalAttrs (config.path != "") { PATH = config.path; };

    in

    { options = {
        environment = mkOption {
          type = types.attrsOf (types.either types.str (types.listOf types.str));
          default = {};
          example = { PATH = "/foo/bar/bin"; LANG = "nl_NL.UTF-8"; };
          description = "Environment variables passed to the service's processes.";
          apply = mapAttrs (n: v: if isList v then concatStringsSep ":" v else v);
        };

        path = mkOption {
          type = types.listOf (types.either types.path types.str);
          default = [];
          description = ''
            Packages added to the service's <envar>PATH</envar>
            environment variable.  Only the <filename>bin</filename>
            and subdirectories of each package is added.
          '';
          apply = ps: if isList ps then (makeDrvBinPath ps) else ps;
        };

        command = mkOption {
          type = types.either types.str types.path;
          default = "";
          description = "Command executed as the service's main process.";
        };

        script = mkOption {
          type = types.lines;
          default = "";
          description = "Shell commands executed as the service's main process.";
        };

        # preStart = mkOption {
        #   type = types.lines;
        #   default = "";
        #   description = ''
        #     Shell commands executed before the service's main process
        #     is started.
        #   '';
        # };

        serviceConfig = mkOption {
          type = types.submodule launchdConfig;
          example =
            { Program = "/run/current-system/sw/bin/nix-daemon";
              KeepAlive = true;
            };
          default = {};
          description = ''
            Each attribute in this set specifies an option for a key in the plist.
            <link xlink:href="https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html"/>
          '';
        };
      };

      config = {
        command = mkIf (config.script != "") (pkgs.writeScript "${name}-start" ''
          #! ${stdenv.shell}

          ${config.script}
        '');

        serviceConfig.Label = mkDefault "${cfg.labelPrefix}.${name}";
        serviceConfig.ProgramArguments = mkIf (cmd != "") [ "/bin/sh" "-c" "exec ${cmd}" ];
        serviceConfig.EnvironmentVariables = mkIf (env != {}) env;
      };
    };
in

{
  options = {
    launchd.labelPrefix = mkOption {
      type = types.str;
      default = "org.home-manager";
      description = ''
        The default prefix of the service label. Individual services can
        override this by setting the Label attribute.
      '';
    };

    launchd.user.agents = mkOption {
      default = {};
      type = types.attrsOf (types.submodule serviceOptions);
      description = ''
        Definition of per-user launchd agents.

        When a user logs in, a per-user launchd is started.
        It does the following:
        1. It loads the parameters for each launch-on-demand user agent from the property list files found in /System/Library/LaunchAgents, /Library/LaunchAgents, and the user’s individual Library/LaunchAgents directory.
        2. It registers the sockets and file descriptors requested by those user agents.
        3. It launches any user agents that requested to be running all the time.
        4. As requests for a particular service arrive, it launches the corresponding user agent and passes the request to it.
        5. When the user logs out, it sends a SIGTERM signal to all of the user agents that it started.
      '';
    };
  };

  config = {
    home.file = mapAttrs' toLaunchAgent cfg.user.agents;
  };
}
