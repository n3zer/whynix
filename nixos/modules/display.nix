{ pkgs, ... }:

{
  services.greetd.enable = false;
  services.displayManager.regreet.enable = false;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    extraPackages = [ pkgs.qt6.qtmultimedia ];
    settings = {
      Theme = {
        CursorTheme = "Adwaita";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    sddm-astronaut
    qt6.qtmultimedia
  ];

  services.accounts-daemon.enable = true;

  hardware.graphics = {
    enable = true;
    # 32-битные драйверы GL — нужно для Steam/Wine/32-битных игр
    enable32Bit = true;

    # Списки МЕРЖАТСЯ с тем, что задаёт модуль hardware.nvidia
    # (nvidia-x11, nvidia-egl-external-platforms, nvidia-vaapi-driver +
    # их 32-битные аналоги). Поэтому mkForce здесь ставить нельзя —
    # он бы выкинул NVIDIA из графического стека.
    extraPackages = with pkgs; [
      # --- VA-API / VDPAU для Intel UHD 630 (Coffee Lake) ---
      # iHD — основной драйвер для Gen8+ (Broadwell и новее, Coffee Lake
      # включительно). Без него /run/opengl-driver/lib/dri/ остаётся
      # без iHD_drv_video.so, и Firefox/Chromium декодируют видео
      # программно, нагружая CPU.
      intel-media-driver
      # i965 (VA-API gen<=7) — запасной вариант для более старых поколений.
      intel-vaapi-driver
      # Мост VDPAU -> VA-API: нужен, чтобы приложения, умеющие только
      # VDPAU (часть плееров/аппаратных ускорителей), работали через
      # общий VA-API интерфейс.
      libvdpau-va-gl
      # --- Vulkan ---
      vulkan-loader # загрузчик ICD; без него драйверы из extraPackages
      # (в т.ч. NVIDIA) не находятся при старте приложений
      vulkan-tools # vulkaninfo для диагностики
    ];

    # 32-битные аналоги — для 32-битного кода (Steam/Wine/игры),
    # которому тоже нужно аппаратное декодирование.
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      intel-vaapi-driver
    ];
  };

  programs.niri.enable = true;
}
