{
  lib,
  pkgs,
  config,
  ...
}:

{
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
      (writeShellApplication {
        name = "claude";
        runtimeInputs = [ nodejs_22 ];
        text = ''
          #!/usr/bin/env bash
          exec npx -y @anthropic-ai/claude-code "$@"
        '';
      })
    ];

    script = ''
      REPO_PATH="/var/opt/godot-mcp"
      REPO_URL="https://github.com/Coding-Solo/godot-mcp"

      # Erstelle Parent-Verzeichnis falls notwendig
      mkdir -p "$(dirname "$REPO_PATH")"

      # Clone Repository wenn es noch nicht existiert
      if [ ! -d "$REPO_PATH" ]; then
        echo "Cloning godot-mcp repository..."
        git clone "$REPO_URL" "$REPO_PATH"
      else
        echo "Repository already exists at $REPO_PATH"
        # Optional: Repository aktualisieren
        cd "$REPO_PATH"
        git pull
      fi

      # Wechsle ins Repository-Verzeichnis
      cd "$REPO_PATH"

      # Führe npm install aus
      echo "Running npm install..."
      npm install

      # Führe npm run build aus
      echo "Running npm run build..."
      npm run build

      echo "godot-mcp setup completed successfully"

      # MCP-Konfiguration zu Claude hinzufügen
      cat <<EOF | claude mcp add-json "godot"
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["$REPO_PATH/build/index.js"],
      "env": {
        "DEBUG": "true"
      },
      "disabled": false,
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
  }
}
EOF
    '';
  };
}
