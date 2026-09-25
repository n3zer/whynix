{ pkgs, ... }:

{
  services.greetd = {
    enable = true;
    useTextGreeter = true;

    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --user n3z --cmd ${pkgs.niri}/bin/niri-session";
        user = "greeter";
      };
    };
  };

  services.displayManager.regreet.enable = false;

  # greeter: прямой доступ к DRM/вводу в VM (libseat/DRM backend)
  users.users.greeter.extraGroups = [ "video" "input" ];

  # compositor
  programs.niri.enable = true;
}
