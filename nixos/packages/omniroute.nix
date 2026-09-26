{ pkgs, lib, config, user ? null, idleTimeout ? "10min" }:

let
  normalUsers = lib.filterAttrs (_: u: u.isNormalUser) config.users.users;
  targetUser = if user != null then user else lib.head (lib.attrNames normalUsers);
  targetHome = config.users.users.${targetUser}.home;

  loopback = "127.0.0.1";
  publicPort = 20128;
  backendPort = 20129;

  omnirouteBin = "${targetHome}/.npm-global/bin/omniroute";

  package = pkgs.writeShellScriptBin "omniroute" ''
    if [ -x "${omnirouteBin}" ]; then
      exec "${omnirouteBin}" "$@"
    elif command -v omniroute >/dev/null 2>&1; then
      exec omniroute "$@"
    else
      exec ${pkgs.nodejs}/bin/npx --yes omniroute@latest "$@"
    fi
  '';

  servicePath = lib.concatStringsSep ":" [
    "${targetHome}/.npm-global/bin"
    "${targetHome}/.nix-profile/bin"
    "${pkgs.systemd}/bin"
    "${pkgs.nodejs}/bin"
    "${pkgs.bash}/bin"
    "${pkgs.coreutils}/bin"
  ];

  proxyd = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd";

  service = {
    description = "OmniRoute backend (${loopback}:${toString backendPort}, on demand)";
    after = [ "network.target" ];
    environment = {
      HOME = targetHome;
      PATH = lib.mkForce servicePath;
      PORT = toString backendPort;
      DASHBOARD_PORT = toString backendPort;
      API_PORT = toString backendPort;
      OMNIROUTE_SERVER_HOST = loopback;
      BROWSER = "false";
      NODE_ENV = "production";
    };
    unitConfig = {
      StopWhenUnneeded = true;
    };
    serviceConfig = {
      Type = "notify";
      NotifyAccess = "all";
      User = targetUser;
      WorkingDirectory = targetHome;
      ExecStart = lib.concatStringsSep " " [
        "${package}/bin/omniroute"
        "serve"
        "--port"
        "${toString backendPort}"
        "--no-open"
        "--no-tray"
      ];
      TimeoutStartSec = "180s";
      TimeoutStopSec = "30s";
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };

  proxy = {
    description = "OmniRoute socket proxy (${loopback}:${toString publicPort} to ${loopback}:${toString backendPort})";
    unitConfig = {
      Requires = [
        "omniroute.service"
        "omniroute.socket"
      ];
      After = [
        "omniroute.service"
        "omniroute.socket"
      ];
    };
    environment = {
      HOME = targetHome;
    };
    serviceConfig = {
      Type = "notify";
      User = targetUser;
      ExecStart = lib.concatStringsSep " " (
        [ proxyd ]
        ++ lib.optional (idleTimeout != null) "--exit-idle-time=${idleTimeout}"
        ++ [ "${loopback}:${toString backendPort}" ]
      );
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };

  socket = {
    description = "OmniRoute on-demand socket (${loopback}:${toString publicPort})";
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = "${loopback}:${toString publicPort}";
      Service = "omniroute-proxy.service";
      Accept = false;
      Backlog = 1024;
      NoDelay = true;
    };
  };
in
{
  inherit package;
  inherit service proxy socket;
}
