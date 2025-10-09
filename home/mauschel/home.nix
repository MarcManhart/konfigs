# `home/mauschel/home.nix` – Home‑Manager für den User
#
# Wofür diese Datei da ist:
#
# - Userland‑Konfiguration: Shell, Prompt, Git‑Identität, direnv, per‑User‑Pakete, Dotfiles. Läuft *unter* dem Benutzer.
#
# Kommentare & Hinweise:
# - `programs.home-manager.enable = true;` – aktiviert HM‑Modul. Gut.
# - Git‑Name/Mail anpassen. Für mehrere Identitäten ggf. `programs.git.includes` nach Verzeichnis.
# - Zsh + Starship + direnv sind klassisch; für Projekte: `nix-direnv` bereits aktiviert.
# - `home.stateVersion = "25.05";` an Release koppeln – nicht vorschnell erhöhen.

{
  config,
  pkgs,
  lib,
  ...
}:
let
  dot = "/home/mauschel/konfigs/home/mauschel/dotfiles";
  styles = "/home/mauschel/konfigs/styling";
  blenderVersion = "4.4";
in
{
  home.username = "mauschel";
  home.homeDirectory = "/home/mauschel";
  programs.home-manager.enable = true;

  # Shell & Prompt
  programs.zsh = {
    enable = true;
    oh-my-zsh.enable = true;
    oh-my-zsh.theme = "robbyrussell";
    shellAliases = {
      ll = "ls -alh";
      gs = "git status";
    };
  };
  programs.starship.enable = true;

  # Cursor
  home.pointerCursor = {
    package = pkgs.adwaita-icon-theme; # alternativ: pkgs.bibata-cursors
    name = "Adwaita"; # oder "Bibata-Modern-Ice"
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Git
  # home.file.".config/git/config" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/git/config";
  #   recursive = true;
  # };

  # Terminator
  home.file.".config/terminator/config" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/terminator/config";
    recursive = true;
    force = true;
  };

  # VIM
  home.file.".vimrc" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.vimrc";
    recursive = true;
    force = true;
  };

  # ZSH
  home.file.".zshrc" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.zshrc";
    force = true;
  };

  # MPlayer
  home.file.".mplayer/config" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.mplayer/config";
    force = true;
  };

  # Neovim
  home.file.".config/nvim/init.lua" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/nvim/init.lua";
    force = true;
  };
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true; # LSP/Tools, falls gebraucht
    withPython3 = true; # optional
    withRuby = false;
    extraPackages = with pkgs; [
      git # lazy.nvim bootstrap braucht git
      wl-clipboard # Wayland clipboard
      xclip # X11 clipboard (GNOME/XWayland)
      ripgrep # nützlich für Suche/Plugins
    ];
  };

  # Hyperland + hyprpaper
  home.file.".config/hypr/hyprland.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/hypr/hyprland.conf";
    recursive = true;
    force = true;
  };
  home.file.".config/hypr/hyprpaper.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/hypr/hyprpaper.conf";
    recursive = true;
    force = true;
  };
  home.file.".config/waybar/power_menu.xml" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/waybar/power_menu.xml";
    recursive = true;
    force = true;
  };
  home.file.".config/waybar/config.jsonc" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/waybar/config.jsonc";
    recursive = true;
    force = true;
  };
  home.file.".config/waybar/style.css" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/waybar/style.css";
    recursive = true;
    force = true;
  };

  # Starship
  home.file.".config/starship.toml" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/starship.toml";
    force = true;
  };

  # Conky
  home.file.".config/conky/conky.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/conky/conky.conf";
    force = true;
  };
  
  # Copyq
  home.file.".config/copyq/copyq.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/copyq/copyq.conf";
    force = true;
  };
  home.file.".config/copyq/copyq-commands.ini" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/copyq/copyq-commands.ini";
    force = true;
  };
  home.file.".config/copyq/copyq_tabs.ini" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/copyq/copyq_tabs.ini";
    force = true;
  };
  # home.file.".config/copyq/themes" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/copyq/themes";
  #   recursive = true;
  #   force = true;
  # };

  # Claude
  home.file.".claude/settings.json" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.claude/settings.json";
    force = true;
  };

  # direnv + nix-direnv (automatische dev-shells in Projekten)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Blender
  home.file.".config/blender/${blenderVersion}/config" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/blender/${blenderVersion}/config";
    recursive = true;
    force = true;
  };
  home.file.".config/blender/${blenderVersion}/scripts/presets/interface_theme/Gruvbox_Dark.xml" = {
    source = config.lib.file.mkOutOfStoreSymlink "${styles}/Themes/Blender/theme-gruvbox-dark-v1.5.0/Gruvbox_Dark.xml";
    force = true;
  };

  ######################################################
  # KDE Einstellungen
  ######################################################
  # home.activation.kdeClean = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
  #   # Nur die kritischen Pfade – erweitere bei Bedarf:
  #   rm -rf \
  #     "${config.home.homeDirectory}/.config/kdeconnect" \
  #     "${config.home.homeDirectory}/.config/kded5rc" \
  #     "${config.home.homeDirectory}/.config/kded6rc" \
  #     "${config.home.homeDirectory}/.config/kdedefaults" \
  #     "${config.home.homeDirectory}/.config/kdeglobals" \
  #     "${config.home.homeDirectory}/.config/kde.org" \
  #     "${config.home.homeDirectory}/.config/kwinoutputconfig.json" \
  #     "${config.home.homeDirectory}/.config/kwinrc" \
  #     "${config.home.homeDirectory}/.config/plasma-localerc" \
  #     "${config.home.homeDirectory}/.config/plasma-org.kde.plasma.desktop-appletsrc" \
  #     "${config.home.homeDirectory}/.config/plasmashellrc" \
  #     "${config.home.homeDirectory}/.config/plasmarc" \
  #     "${config.home.homeDirectory}/.config/plasmanotifyrc" \
  #     "${config.home.homeDirectory}/.config/Trolltech.conf"
  # '';

  # # KDE Connect
  # home.file.".config/kdeconnect" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/kdeconnect";
  #   force = true;
  # };

  # # KDE Daemon configs
  # home.file.".config/kded5rc" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/kded5rc";
  #   force = true;
  # };
  # home.file.".config/kded6rc" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/kded6rc";
  #   force = true;
  # };

  # # KDE defaults folder
  # home.file.".config/kdedefaults" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/kdedefaults";
  #   force = true;V
  # home.file.".config/kde.org" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/kde.org";
  #   force = true;
  #   recursive = true;
  # };

  # # KWin configs
  # home.file.".config/kwinoutputconfig.json" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/kwinoutputconfig.json";
  #   force = true;
  # };
  # home.file.".config/kwinrc" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/kwinrc";
  #   force = true;
  # };

  # # Plasma configs
  # home.file.".config/plasma-localerc" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/plasma-localerc";
  #   force = true;
  # };
  # home.file.".config/plasma-org.kde.plasma.desktop-appletsrc" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/plasma-org.kde.plasma.desktop-appletsrc";
  #   force = true;
  # };
  # home.file.".config/plasmashellrc" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/plasmashellrc";
  #   force = true;
  # };

  # # Additional Plasma configs for themes and notifications
  # home.file.".config/plasmarc" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/plasmarc";
  #   force = true;
  # };
  # home.file.".config/plasmanotifyrc" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/plasmanotifyrc";
  #   force = true;
  # };

  # # Qt/KDE theme config
  # home.file.".config/Trolltech.conf" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${dot}/.config/Trolltech.conf";
  #   force = true;
  # };

  ######################################################
  # Gnome Einstellungen
  ######################################################
  # Gruvbox Icon Theme
  # home.file.".local/share/icons/Gruvbox" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${styles}/Icons/Gruvbox";
  #   recursive = true;
  # };

  # Gruvbox GTK Theme
  # GTK3 Theme (gesamter Ordner)
  home.file.".themes/Gruvbox-Dark" = {
    source = config.lib.file.mkOutOfStoreSymlink "${styles}/Themes/Gruvbox-Dark-BL-LB/Gruvbox-Dark";
    recursive = true;
  };

  # GTK4 Theme (nur assets, gtk.css und gtk-dark.css)
  home.file.".config/gtk-4.0/assets" = {
    source = config.lib.file.mkOutOfStoreSymlink "${styles}/Themes/Gruvbox-Dark-BL-LB/Gruvbox-Dark/gtk-4.0/assets";
    recursive = true;
  };
  home.file.".config/gtk-4.0/gtk.css" = {
    source = config.lib.file.mkOutOfStoreSymlink "${styles}/Themes/Gruvbox-Dark-BL-LB/Gruvbox-Dark/gtk-4.0/gtk.css";
  };
  home.file.".config/gtk-4.0/gtk-dark.css" = {
    source = config.lib.file.mkOutOfStoreSymlink "${styles}/Themes/Gruvbox-Dark-BL-LB/Gruvbox-Dark/gtk-4.0/gtk-dark.css";
  };

  # DConf Settings
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      text-scaling-factor = 1.0;
      enable-hot-corners = true;
      # icon-theme = "Gruvbox";
      gtk-theme = "Gruvbox-Dark";
    };
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
    };

    "org/gnome/shell" = {
      enabled-extensions = [
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "dash-to-dock@micxgx.gmail.com"
        "appindicatorsupport@rgcjonas.gmail.com"
        "mock-tray@kramo.page"
        "gsconnect@andyholmes.github.io"
        # "blur-my-shell@aunetx"  # wenn du sie auch aktiv setzen willst
      ];
      favorite-apps = [
        "brave-browser.desktop"
        "firefox.desktop"
        "thunderbird.desktop"
        "slack.desktop"
        "org.gnome.Nautilus.desktop"
        "org.gnome.Settings.desktop"
        "org.gnome.tweaks.desktop"
        "obsidian.desktop"
        "spotify.desktop"
        "megasync.desktop"
        "discord.desktop"
        "org.kde.digikam.desktop"
        "pureref.desktop"
        "virt-manager.desktop"
        "blender_blender.desktop"
        "terminator.desktop"
        "bruno.desktop"
        "code.desktop"
        "1password.desktop"
      ];
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Gruvbox-Dark";
    };

    # >>> Das zeigt die Minimize/Maximize/Close-Buttons an (rechts)
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      # optional nett:
      action-double-click-titlebar = "toggle-maximize";
      action-middle-click-titlebar = "minimize";
      # Fenster mit Super+Mausklicks verschieben/größe ändern
      mouse-button-modifier = "<Super>";
      resize-with-right-button = true;
    };


    "org/gnome/desktop/wm/keybindings" = {
      switch-applications = [ ];
      switch-applications-backward = [ ];

      switch-windows = [
        "<Alt>Tab"
        "<Super>Tab"
      ];
      switch-windows-backward = [
        "<Shift><Alt>Tab"
        "<Shift><Super>Tab"
      ];
    };

    "org/gnome/shell/keybindings" = {
      # Screenshot-Tool auf Super+Shift+S setzen
      show-screenshot-ui = [ "<Super><Shift>s" ];
      # Super+V Shortcut für Message-Tray deaktivieren (nur Super+M behalten)
      toggle-message-tray = [ "<Super>m" ];
    };

    # Benutzerdefinierte Keybindings
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>v";
      command = "env QT_QPA_PLATFORM=xcb GDK_BACKEND=x11 copyq show";
      name = "CopyQ - Clipboard Manager";
    };

    "org/gnome/desktop/background" = {
      # hier mit file:// Prefix!
      picture-uri = "file://${styles}/Wallpapers/stairs.png";
      picture-uri-dark = "file://${styles}/Wallpapers/stairs.png";
      picture-options = "zoom"; # oder "scaled", "centered", "stretched"
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      transparency-mode = "FIXED"; # statt "DEFAULT"/"DYNAMIC"
      custom-background-color = true; # erlaubt eigene Farbe
      background-color = "#1d2021"; # RGB ohne Alpha
      background-opacity = 1.0; # 0.0–1.0; hier voll deckend
      # optional nützlich:
      # apply-custom-theme = false;        # falls das Built-in-Theme dich überfährt
    };

  };

  ######################################################
  # Zusatzpakete nur für den User
  ######################################################
  home.packages = with pkgs; [
  ];

  # Systemd User Services
  systemd.user.services.copyq = {
    Unit = {
      Description = "CopyQ clipboard manager";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.writeShellScript "copyq-wayland" ''
        # Wayland-kompatible Umgebungsvariablen setzen
        export QT_QPA_PLATFORM=xcb
        export GDK_BACKEND=x11
        export COPYQ_CLIPBOARD_MODE=selection
        exec ${pkgs.copyq}/bin/copyq "$@"
      ''}";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
      Environment = [
        "QT_QPA_PLATFORM=xcb"
        "GDK_BACKEND=x11"
      ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # WICHTIG: zur Systemversion passend
  home.stateVersion = "25.05";
}
