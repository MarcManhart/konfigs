{
  lib,
  pkgs,
  config,
  ...
}:

{
  # System-level service to clone and build the repository
  systemd.services.godot-mcp-setup = {
    description = "Clone and build godot-mcp repository";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };

    path = with pkgs; [
      git
      nodejs_22
      bash
      coreutils
      godot-mono
    ];

    script = ''
        REPO_PATH="/var/opt/godot-mcp"
        REPO_URL="https://github.com/Coding-Solo/godot-mcp"

        mkdir -p "$(dirname "$REPO_PATH")"

        if [ ! -d "$REPO_PATH" ]; then
          echo "Cloning godot-mcp repository..."
          git clone "$REPO_URL" "$REPO_PATH"
        else
          echo "Repository already exists at $REPO_PATH"
          cd "$REPO_PATH"
          git pull
        fi

        cd "$REPO_PATH"

        echo "Running npm install..."
        npm install

        echo "Running npm run build..."
        npm run build

        # Make the build directory readable by all users
        chmod -R a+rX "$REPO_PATH"

        echo "godot-mcp setup completed successfully"
    '';
  };

  # User-level service to configure Claude MCP
  systemd.user.services.godot-mcp-config = {
    description = "Configure Claude MCP for Godot";
    wantedBy = [ "default.target" ];
    after = [ "godot-mcp-setup.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = with pkgs; [
      nodejs_22
      jq
      bash
      coreutils
      (writeShellApplication {
        name = "claude";
        runtimeInputs = [ nodejs_22 ];
        text = ''
          exec npx -y @anthropic-ai/claude-code "$@"
        '';
      })
    ];

    script = ''
      CLAUDE_CONFIG="$HOME/.claude.json"

      # Wait for the system service to complete building
      while [ ! -f "/var/opt/godot-mcp/build/index.js" ]; do
        echo "Waiting for godot-mcp to be built..."
        sleep 2
      done

      # Ensure Claude config file exists
      if [ ! -f "$CLAUDE_CONFIG" ]; then
        echo "{}" > "$CLAUDE_CONFIG"
      fi

      # Create the MCP server configuration
      MCP_CONFIG=$(cat <<EOF
      {
        "type": "stdio",
        "command": "node",
        "args": ["/var/opt/godot-mcp/build/index.js"],
        "env": {
          "DEBUG": "true",
          "GODOT_PATH": "/etc/profiles/per-user/mauschel/bin/godot-mono"
        },
        "autoApprove": [
          "launch_editor",
          "run_project",
          "get_debug_output",
          "stop_project",
          "get_godot_version",
          "list_projects",
          "get_project_info",
          "create_scene",
          "add_node",
          "load_sprite",
          "export_mesh_library",
          "save_scene",
          "get_uid",
          "update_project_uids"
        ]
      }
EOF
      )

      # Update the Claude configuration file with jq
      echo "Updating Claude MCP configuration for user..."

      # Backup current config
      cp "$CLAUDE_CONFIG" "$CLAUDE_CONFIG.backup.$(date +%s)"

      # Add or update the godot MCP server configuration
      jq --argjson mcp "$MCP_CONFIG" '.mcpServers.godot = $mcp' "$CLAUDE_CONFIG" > "$CLAUDE_CONFIG.tmp" && mv "$CLAUDE_CONFIG.tmp" "$CLAUDE_CONFIG"

      echo "Claude MCP configuration updated successfully for user $USER"

      # Verify the configuration
      if jq -e '.mcpServers.godot' "$CLAUDE_CONFIG" > /dev/null; then
        echo "Configuration verified: godot MCP server is configured"
      else
        echo "Warning: Failed to verify godot MCP configuration"
        exit 1
      fi
    '';
  };

  # Ensure claude command is available in all user shells
  environment.systemPackages = with pkgs; [
    (writeShellApplication {
      name = "claude";
      runtimeInputs = [ nodejs_22 ];
      text = ''
        exec npx -y @anthropic-ai/claude-code "$@"
      '';
    })
  ];
}