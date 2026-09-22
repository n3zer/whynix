{ pkgs, lib, config, user ? null }:

let
  normalUsers = lib.filterAttrs (_: u: u.isNormalUser) config.users.users;
  targetUser = if user != null then user else lib.head (lib.attrNames normalUsers);
  targetHome = config.users.users.${targetUser}.home;
in
{
  package = pkgs.writeShellScriptBin "omniroute" ''
    exec ${pkgs.nodejs}/bin/npx --yes omniroute@latest "$@"
  '';

  service = {
    description = "OmniRoute Local AI Router Service";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      PORT = "20128";
      HOME = targetHome;
      PATH = lib.mkForce "${targetHome}/.npm-global/bin:${targetHome}/.nix-profile/bin:${pkgs.nodejs}/bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin";
    };

    serviceConfig = {
      Type = "simple";
      User = targetUser;
      WorkingDirectory = targetHome;
      ExecStart = "${pkgs.bash}/bin/bash -lc 'npx --yes omniroute@latest'";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
