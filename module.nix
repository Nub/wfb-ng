wfb_pkg:
{ lib, config, ... }:
with lib;
let cfg = config.services.wfb;
in {
  options.services.wfb = {
    enable = mkEnableOption "Enable WFB-NG Module";
    pkg = mkOption {
      type = types.package;
      default = wfb_pkg;
      description = "The wfb package to use";
    };
    profiles = mkOption {
      type = types.list;
      default = [ "udp_gs" ];
      apply = x: strings.concatStrings (strings.intersperse ":" x);
      description = "The profiles to run from the config";
    };
    interfaces = mkOption {
      type = types.list;
      default = [ "wfb0" ];
      apply = x: strings.concatStrings (strings.intersperse " " x);
      description = "The interface to run the server on";
    };
    # TODO: support config files for providing profiles etc
    # config = mkOption {
    #   type = types.pkg;
    #   default = default_cfg
    # };
    # TODO:
    # tx_power = mkOption {
    #   type = types.int;
    #   default = 20;
    #   description = "The TX power to configure the interface to use";
    # };
  };

  config = mkIf cfg.enable {
    boot.extraModulePackages = with config.boot.kernelPackages;
      [ rtl88xxau-aircrack ];

    networking.firewall.interfaces.wfb0 = {
      allowedTCPPorts = [ 22 2222 14550 9000 9001 ];
      allowedUDPPortRanges = [{
        from = 14000;
        to = 15000;
      }];
    };

    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", DRIVERS=="rtl88XXau", NAME="wfb0"
    '';

    systemd.services.wfb = {
      enable = cfg.enable;
      description = "WFB-NG service";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      restartIfChanged = true;

      serviceConfig = {
        User = "root";
        WorkingDirectory = "${cfg.working_dir}";
        ExecStart =
          "${cfg.pkg}/bin/wfb-server ${cfg.profiles} ${cfg.interfaces}";
        Restart = "always";
      };
    };

  };
}
