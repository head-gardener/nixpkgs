{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.hqplayerd;
  pkg = pkgs.hqplayerd;
  # XXX: This is hard-coded in the distributed binary, don't try to change it.
  stateDir = "/var/lib/hqplayer";
  configDir = "/etc/hqplayer";
in
{
  options = {
    services.hqplayerd = {
      enable = mkEnableOption "HQPlayer Embedded";

      licenseFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to the HQPlayer license key file.

          Without this, the service will run in trial mode and restart every 30
          minutes.
        '';
      };

      auth = {
        username = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Username used for HQPlayer's WebUI.

            Without this you will need to manually create the credentials after
            first start by going to http://your.ip/8088/auth
          '';
        };

        password = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Password used for HQPlayer's WebUI.

            Without this you will need to manually create the credentials after
            first start by going to http://your.ip/8088/auth
          '';
        };
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Open TCP port 8088 in the firewall for the server.
        '';
      };

      user = mkOption {
        type = types.str;
        default = "hqplayer";
        description = ''
          User account under which hqplayerd runs.
        '';
      };

      group = mkOption {
        type = types.str;
        default = "hqplayer";
        description = ''
          Group account under which hqplayerd runs.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.auth.username != null -> cfg.auth.password != null)
                 && (cfg.auth.password != null -> cfg.auth.username != null);
        message = "You must set either both services.hqplayer.auth.username and password, or neither.";
      }
    ];

    environment = {
      etc = {
        "hqplayer/hqplayerd4-key.xml" = mkIf (cfg.licenseFile != null) { source = cfg.licenseFile; };
        "modules-load.d/taudio2.conf".source = "${pkg}/etc/modules-load.d/taudio2.conf";
      };
      systemPackages = [ pkg ];
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 8088 ];
    };

    services.udev.packages = [ pkg ];

    systemd = {
      tmpfiles.rules = [
        "d ${configDir}      0755 ${cfg.user} ${cfg.group} - -"
        "d ${stateDir}       0755 ${cfg.user} ${cfg.group} - -"
        "d ${stateDir}/home  0755 ${cfg.user} ${cfg.group} - -"
      ];

      services.hqplayerd = {
        description = "HQPlayer daemon";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" "sound.target" "systemd-udev-settle.service" ];
        after = [ "network-online.target" "sound.target" "systemd-udev-settle.service" "local-fs.target" "remote-fs.target" "systemd-tmpfiles-setup.service" ];

        environment.HOME = "${stateDir}/home";

        unitConfig.ConditionPathExists = [ configDir stateDir ];

        preStart = ''
          cp -r "${pkg}/var/lib/hqplayer/web" "${stateDir}"
          chmod -R u+wX "${stateDir}/web"

          if [ ! -f "${configDir}/hqplayerd.xml" ]; then
            echo "creating initial config file"
            install -m 0644 "${pkg}/etc/hqplayer/hqplayerd.xml" "${configDir}/hqplayerd.xml"
          fi
        '' + optionalString (cfg.auth.username != null && cfg.auth.password != null) ''
          ${pkg}/bin/hqplayerd -s ${cfg.auth.username} ${cfg.auth.password}
        '';

        serviceConfig = {
          ExecStart = "${pkg}/bin/hqplayerd";

          User = cfg.user;
          Group = cfg.group;

          Restart = "on-failure";
          RestartSec = 5;

          Nice = -10;
          IOSchedulingClass = "realtime";
          LimitMEMLOCK = "1G";
          LimitNICE = -10;
          LimitRTPRIO = 98;
        };
      };
    };

    users.groups = mkIf (cfg.group == "hqplayer") {
      hqplayer.gid = config.ids.gids.hqplayer;
    };

    users.users = mkIf (cfg.user == "hqplayer") {
      hqplayer = {
        description = "hqplayer daemon user";
        extraGroups = [ "audio" ];
        group = cfg.group;
        uid = config.ids.uids.hqplayer;
      };
    };
  };
}
