# Buildlinx step-cli SSH certificate handling
{ pkgs, config, lib, ... }:
{
  # Install step-cli and helper script
  environment.systemPackages = with pkgs; [
    step-cli
    (writeShellScriptBin "step-init-buildlinx" ''
      #!/usr/bin/env bash
      # Initialize step for Buildlinx CA

      if [ -f "$HOME/.step/config/defaults.json" ]; then
        echo "Step is already configured for user $USER"
      else
        echo "Bootstrapping step CA for Buildlinx..."
        ${step-cli}/bin/step ca bootstrap \
          --ca-url https://ca.buildlinx.io:9000 \
          --fingerprint 758638f98f14b0bbd674dbf7fd0828604a5da94f37a00f5cf4988c2c16a50d35 \
          --force
        echo "Step CA bootstrapped successfully!"
      fi
    '')
  ];

  # User-specific step configuration
  environment.interactiveShellInit = ''
    # Auto-initialize step if not configured
    if [ ! -f "$HOME/.step/config/defaults.json" ] && command -v step >/dev/null 2>&1; then
      echo "Initializing step CA for Buildlinx..."
      ${pkgs.step-cli}/bin/step ca bootstrap \
        --ca-url https://ca.buildlinx.io:9000 \
        --fingerprint 758638f98f14b0bbd674dbf7fd0828604a5da94f37a00f5cf4988c2c16a50d35 \
        --force >/dev/null 2>&1
      echo "Step CA initialized. You can now use 'step ssh login'."
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