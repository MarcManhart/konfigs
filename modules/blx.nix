# Buildlinx step-cli SSH certificate handling
{ pkgs, config, lib, ... }:
{
  # Install step-cli
  environment.systemPackages = with pkgs; [
    step-cli
  ];

  # Configure step CA for Buildlinx
  environment.etc."step/config/defaults.json".text = ''
    {
      "ca-url": "https://ca.buildlinx.io:9000",
      "fingerprint": "758638f98f14b0bbd674dbf7fd0828604a5da94f37a00f5cf4988c2c16a50d35",
      "root": "/etc/step/certs/root_ca.crt"
    }
  '';

  # System-wide step configuration
  environment.variables = {
    STEPPATH = "/etc/step";
  };

  # Create necessary directories
  systemd.tmpfiles.rules = [
    "d /etc/step 0755 root root -"
    "d /etc/step/config 0755 root root -"
    "d /etc/step/certs 0755 root root -"
  ];

  # Bootstrap script for users
  environment.etc."profile.d/step-ca.sh".text = ''
    # Bootstrap step CA if not already done for user
    if [ ! -f "$HOME/.step/config/defaults.json" ]; then
      echo "Initializing step CA for user..."
      step ca bootstrap \
        --ca-url https://ca.buildlinx.io:9000 \
        --fingerprint 758638f98f14b0bbd674dbf7fd0828604a5da94f37a00f5cf4988c2c16a50d35 \
        --force 2>/dev/null || true
    fi
  '';

  # SSH client configuration for step certificates
  programs.ssh.extraConfig = ''
    # Use step for SSH certificates
    Host *.buildlinx.io
      ProxyCommand step ssh proxycommand %h %p
      UserKnownHostsFile /dev/null
      StrictHostKeyChecking no
  '';
}