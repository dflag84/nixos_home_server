{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # --- Boot & Kernel ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "deadbeef"; # Required for ZFS (generate your own: head -c 8 /etc/machine-id)

  # --- Networking & Remote Access ---
  networking.hostName = "homestat";
  services.tailscale.enable = true;
  networking.firewall.checkReversePath = "loose"; # Better compatibility with Tailscale

  # --- ZFS Storage Layout ---
  fileSystems."/mnt/storage" = {
    device = "tank";
    fsType = "zfs";
  };

  # --- Services (Native Nix Modules) ---
  
  # 1. Jellyfin
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # 2. Nextcloud
  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.local"; # Or your Tailscale magicDNS name
    datadir = "/mnt/storage/nextcloud";
    package = pkgs.nextcloud29;
    config = {
      adminpassFile = "/etc/nextcloud-admin-pass"; # Create this file manually
      dbtype = "sqlite"; # Simplified for home use, use postgres for many users
    };
  };

  # 3. Immich (Native Module)
  services.immich = {
    enable = true;
    mediaLocation = "/mnt/storage/immich";
    host = "0.0.0.0";
  };

  # 4. Home Assistant
  services.home-assistant = {
    enable = true;
    extraComponents = [ "default_config" "met" "esphome" ];
    config = {
      # HA configuration.yaml content can go here
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" "::1" ];
      };
    };
  };

  # --- System Maintenance ---
  # Periodic ZFS scrubbing to check for bitrot
  services.zfs.autoScrub.enable = true;
  
  # Automatic garbage collection to keep NVMe healthy
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "24.11";
}
