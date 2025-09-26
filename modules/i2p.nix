{ config, lib, pkgs, ... }:

{
  services.i2pd = {
    enable = true;
    bandwidth = 4096;
    port = 4567;
    enableIPv4 = true;
    enableIPv6 = true;
    floodfill = true;
    proto = {
      http = {
        enable = true;
        address = "127.0.0.1";
        port = 7070;
      };
      socksProxy = {
        enable = true;
        address = "127.0.0.1";
        port = 4447;
      };
      sam = {
        enable = true;
        address = "127.0.0.1";
        port = 7656;
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      4567
      7070
      4447
      7656
    ];
    allowedUDPPorts = [
      4567
    ];
  };

  environment.systemPackages = with pkgs; [
    i2pd
    i2p
  ];

}