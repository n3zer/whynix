# Проприетарный драйвер NVIDIA + гибридная графика PRIME render offload.
#
# Железо ноутбука: Intel UHD 630 (Coffee Lake, iGPU) + NVIDIA GTX 1060 Mobile
# (Pascal, dGPU). Рабочий стол niri рендерится на Intel, NVIDIA спит и
# просыпается только под нагрузкой через `nvidia-offload`.
#
# Подключается ТОЛЬКО из nixos/profiles/laptop.nix. На хосте n3zer-vm
# (VirtualBox, vmsvga) проприетарный драйвер не нужен и ломает гостя.
{ config, lib, pkgs, ... }:

{
  # Список драйверов Xorg. Модуль nvidia НЕ выставляет его сам — он только
  # читает (hardware.nvidia.enabled = "nvidia" elem videoDrivers), поэтому без
  # явной строки весь блок ниже просто не активируется.
  # modesetting остаётся ради Intel UHD 630: на ней крутятся niri и XWayland,
  # без него упадёт весь Wayland-стек. fbdev убран намеренно, чтобы не отдать
  # консоль фреймбуферу.
  services.xserver.videoDrivers = [
    "nvidia"
    # modesetting ОБЯЗАТЕЛЕН и не может быть убран. На нём работает Intel
    # UHD 630, а на ней крутятся niri (панель eDP-1) и XWayland. Если оставить
    # только "nvidia", модуль hardware.nvidia не создаст секцию Device для
    # iGPU в xorg.conf, i915 перестанет инициализироваться, и XWayland упадёт
    # вместе с ним — то есть сломается весь Wayland-стек, а не только X11.
    "modesetting"
  ];

  hardware.nvidia = {
    # Pascal (GTX 1060) НЕ поддерживает открытые ядерные модули — только
    # проприетарные. На драйверах >=560 nixpkgs требует явного значения open,
    # иначе падает assertion. Для Turing+ можно ставить true.
    open = false;

    # Обязательно для Wayland: включает nvidia-drm.modeset=1, иначе niri
    # не сможет работать на выходах, подключённых к dGPU.
    modesetting.enable = true;

    powerManagement = {
      # Поднимает nvidia-suspend/nvidia-resume/hibernate + ставит
      # NVreg_PreserveVideoMemoryAllocations=1 (VRAM переживает suspend).
      enable = true;

      # finegrained = NVreg_DynamicPowerManagement=0x02 (RTD3, Chapter 22
      # README драйвера). NVIDIA явно пишет: "requires a Turing or newer GPU".
      # Pascal это значение игнорирует, поэтому оно выключено — иначе получим
      # молчаливо неработающую настройку. Базовая экономия энергии приходит из
      # powerManagement.enable + PRIME offload.
      finegrained = false;
    };

    # ВАЖНО: НЕ stable. Ветка stable сейчас = 595.x, а NVIDIA официально
    # прекратила поддержку Maxwell/Pascal/Volta после ветки 580
    # ("the release 580 series will be the last to support GPUs based on the
    # Maxwell, Pascal, and Volta architectures"). На 595 модуль ядра просто не
    # подхватит GTX 1060. legacy_580 = 580.178.04, LTSB до октября 2028.
    # Если когда-нибудь появится поддержка Pascal в новой ветке — вернуться
    # на stable можно будет одной строкой.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

    # nvidia-settings — GUI для X11. В чистом Wayland (niri) не нужен,
    # диагностика делается через nvidia-smi / glxinfo / switcherooctl.
    nvidiaSettings = false;

    prime = {
      offload = {
        enable = true;
        # Кладёт скрипт nvidia-offload в PATH: nvidia-offload <команда>.
        enableOffloadCmd = true;
      };

      # Проверено по sysfs на ноутбуке (/sys/bus/pci/devices):
      #   0000:00:02.0  8086:3e9b  Intel UHD 630 (Coffee Lake-H) -> i915
      #   0000:01:00.0  10de:1c20  GeForce GTX 1060 Mobile (GP106)
      #   0000:01:00.1  10de:10f1  HDMI-аудио того же dGPU, не display-class
      # Display-устройств ровно два, поэтому IDs однозначны.
      #
      # Формат nixpkgs: PCI:<домен>@<шина>:<устройство>:<функция>.
      # Домен ОБЯЗАТЕЛЕН — без "@0" значение не соответствует ожидаемой
      # разметке, поэтому писать надо "PCI:0@0:2:0", а не "PCI:0:2:0".
      # Значения ДЕСЯТИЧНЫЕ (lspci печатает шестнадцатеричные; тут все цифры
      # < 10, так что разницы нет).
      #
      # Факт: с этими ID PRIME offload проверен вживую —
      #   nvidia-offload glxinfo -B -> "NVIDIA GeForce GTX 1060 with Max-Q Design"
      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:0@1:0:0";
    };
  };

  # services.xserver.enable = false (на niri Xorg не нужен), а модуль
  # hardware.nvidia добавляет nvidia* в boot.kernelModules именно под этим
  # условием (nixos/modules/hardware/video/nvidia.nix, секция
  # `kernelModules = lib.optionals config.services.xserver.enable`).
  # Без явной строки они грузятся только через udev по modalias, что
  # работает, но ставит загрузку dGPU в зависимость от порядка запуска
  # udev. Перечисляем явно — initrd поднимет их до появления графики.
  #
  # nvidia_uvm здесь намеренно отсутствует: его надо грузить ПОСЛЕ nvidia,
  # когда udev уже создал /dev/nvidia* — это делает softdep из
  # modprobe.d, который добавляет сам модуль hardware.nvidia.
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_drm"
  ];

  # nvidia-drm в режиме KMS: без modeset=1 niri не сможет работать на
  # выходах, подключённых к dGPU, плюс рвётся кадр при PRIME.
  # Параметры modeset=1/fbdev=1 и NVreg_PreserveVideoMemoryAllocations=1
  # проставляет сам модуль hardware.nvidia из modesetting.enable и
  # powerManagement.enable — дублировать их вручную не нужно.

  # ── dgpu-offload ────────────────────────────────────────────────────────────
  # Обёртка для PRIME render offload: `dgpu-offload firefox`.
  #
  # Чем отличается от nvidia-offload из nixpkgs: тот выставляет только
  # __NV_PRIME_RENDER_OFFLOAD + __GLX_VENDOR_LIBRARY_NAME (это GLX/GL) и
  # __VK_LAYER_NV_optimus (Vulkan). Переменной __EGL_VENDOR_LIBRARY_FILENAMES
  # в нём нет, поэтому EGL-приложения (Firefox, Qt/Quickshell, Electron) на
  # Wayland продолжают получать iGPU: eglGetDisplay(EGL_DEFAULT_DISPLAY)
  # отдаёт boot-GPU, то есть Intel. Проверено на этой машине:
  #   eglinfo                 -> EGL vendor string: NVIDIA, но device[0] = Intel
  #   nvidia-offload glxinfo  -> NVIDIA, и это GLX, а не EGL
  # Ограничение EGL-диспетчера в том, что его список вендоров берётся из
  # /usr/share/glvnd/egl_vendor.d, которого на NixOS нет; glvnd молча
  # перечисляет Intel, и оффлоад не происходит. Явный __EGL_VENDOR_
  # LIBRARY_FILENAMES оставляет единственным вендором NVIDIA.
  #
  # switcherooctl launch не подходит: switcherooctl помечает карту как
  # "Discrete: no" и не считает её дискретной, поэтому переменные не
  # выставляет (проверено: switcherooctl launch glxinfo -B -> Intel).
  #
  # ЧТО ЭТО НЕ ДЕЛАЕТ: внутренний экран (eDP-1) подключён к iGPU —
  #   /sys/class/drm/card1-eDP-1/status = connected, card1 = i915
  #   /sys/class/drm/card0 (nvidia) имеет только HDMI-A-2, и он отключён.
  # То есть niri в любом случае композитит на Intel, и картинка с dGPU
  # приходит в iGPU копированием. Выигрыш — в том, что тяжёлая растеризация
  # снимается с UHD 630; расплата — лишний перенос через PCIe.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "dgpu-offload" ''
      # Рендерит переданную команду на NVIDIA вместо встроенной Intel UHD 630.
      # Использование: dgpu-offload firefox
      #
      # Видеодекодирование НЕ переносится: LIBVA_DRIVER_NAME=iHD остаётся
      # от сессии, поэтому VA-API decode по-прежнему на iGPU. Для видео это
      # лишний копирующий обмен Intel->NVIDIA->Intel, так что страницы с
      # одним лишь видео лучше запускать без обёртки.
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __EGL_VENDOR_LIBRARY_FILENAMES="${config.hardware.nvidia.package}/share/glvnd/egl_vendor.d/10_nvidia.json"
      export __VK_LAYER_NV_optimus=NVIDIA_only
      export VK_LOADER_DRIVERS_SELECT='*nvidia*'
      exec "$@"
    '')
  ];

  assertions = [
    {
      assertion = builtins.pathExists "${config.hardware.nvidia.package}/share/glvnd/egl_vendor.d/10_nvidia.json";
      message = "dgpu-offload: в ${config.hardware.nvidia.package} нет share/glvnd/egl_vendor.d/10_nvidia.json — EGL-оффлоад на NVIDIA не заработает.";
    }
  ];

  environment.sessionVariables = {
    # NVD_BACKEND=direct — без лишнего промежуточного копирования кадра.
    NVD_BACKEND = "direct";

    # Electron/Discord/VSCode — автовыбор нативного Wayland вместо XWayland.
    ELECTRON_OZONE_PLATFORM_HINT = "auto";

    # Аппаратное декодирование видео — строго на Intel UHD 630.
    # iHD обслуживает Gen8+ (Broadwell и новее), куда попадает Coffee Lake;
    # i965 из intel-vaapi-driver на этом GPU неприменим. Пинтим драйвер явно,
    # иначе libva при неоднозначном наборе драйверов в /run/opengl-driver
    # может выбрать не тот, и декодирование уедет в софтвер на CPU.
    #
    # Побочный эффект: NVIDIA VA-API (nvidia_drv_video.so) исключается из
    # выбора. Это осознанно — декодировать видео должна iGPU, а не dGPU,
    # иначе 3D-карта перестанет засыпать. GL/GLX этим НЕ затрагивается
    # (для них отдельная переменная __GLX_VENDOR_LIBRARY_NAME, которую
    # задавать нельзя — она сломала бы ускорение на Intel).
    LIBVA_DRIVER_NAME = "iHD";
  };
}
