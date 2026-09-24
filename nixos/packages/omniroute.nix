{ pkgs, lib, config, user ? null }:

let
  normalUsers = lib.filterAttrs (_: u: u.isNormalUser) config.users.users;
  targetUser = if user != null then user else lib.head (lib.attrNames normalUsers);
  targetHome = config.users.users.${targetUser}.home;

  # omniroute установлен локально (npm --prefix ~/.npm-global, см. README):
  # без npx/скачиваний при каждом запуске. PATH ниже указывает на него.
  omnirouteBin = "${targetHome}/.npm-global/bin/omniroute";

  backendEnv = {
    PORT = "20129";
    HOME = targetHome;
    PATH = lib.concatStringsSep ":" [
      "${targetHome}/.npm-global/bin"
      "${targetHome}/.nix-profile/bin"
      "${pkgs.nodejs}/bin"
      "${pkgs.bash}/bin"
      "${pkgs.coreutils}/bin"
    ];
  };

  # Реальный AI-роутер. Запускается ТОЛЬКО при первом обращении к :20128,
  # работает на :20129. Без трафика в RAM не живёт (~700MB в стоке не тратится).
  backend = pkgs.writeShellScriptBin "omniroute-backend" ''
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}=\"${v}\"") backendEnv)}
    if [ ! -x "${omnirouteBin}" ]; then
      echo "omniroute-backend: ${omnirouteBin} не найден — выполните: npm install --global omniroute --prefix \$HOME/.npm-global" >&2
      exit 1
    fi
    exec "${omnirouteBin}"
  '';

  # launcher, который socat-фронт зовёт на каждое соединение:
  # поднимает бэкенд (flock — только один раз) и пробрасывает сокет дальше.
  lazy = pkgs.writeShellScriptBin "omniroute-lazy" ''
    probe() { ${pkgs.socat}/bin/socat -T 1 TCP:127.0.0.1:20129 STDIO </dev/null >/dev/null 2>&1; }
    if probe; then
      exec ${pkgs.socat}/bin/socat STDIO TCP:127.0.0.1:20129,retry=5,interval=1
    fi
    (
      flock 9
      if ! probe; then
        ${pkgs.util-linux}/bin/setsid ${backend} </dev/null >/dev/null 2>&1 &
        for i in $(seq 1 60); do probe && break; sleep 0.1; done
      fi
      exec ${pkgs.socat}/bin/socat STDIO TCP:127.0.0.1:20129,retry=5,interval=1
    ) 9>/tmp/omniroute.lock
  '';
in
{
  package = pkgs.writeShellScriptBin "omniroute" ''
    if [ ! -x "${omnirouteBin}" ]; then
      echo "omniroute: ${omnirouteBin} не найден — выполните: npm install --global omniroute --prefix \$HOME/.npm-global" >&2
      exit 1
    fi
    exec "${omnirouteBin}" "$@"
  '';

  front = {
    description = "OmniRoute lazy front (20128 → on-demand backend 20129, socat)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = { HOME = targetHome; };

    serviceConfig = {
      Type = "simple";
      User = targetUser;
      WorkingDirectory = targetHome;
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:20128,fork,reuseaddr,bind=127.0.0.1 EXEC:${lazy}/bin/omniroute-lazy";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}