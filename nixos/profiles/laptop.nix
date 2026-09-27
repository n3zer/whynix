# Bare-metal host profile (.#n3zer).
#
# The VM has its own profile: ./virtualbox-guest.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ../hardware-configuration.nix
    # проприетарный NVIDIA + PRIME offload (ноутбук: Intel UHD 630 + GTX 1060)
    ../modules/nvidia.nix
  ];

  networking.hostName = "nixos-laptop";

  # Аппаратные параметры ноутбука HP Pavilion (Intel UHD 630 + GTX 1060 Mobile)
  hardware.nvidia.prime = {
    intelBusId = "PCI:0@0:2:0";
    nvidiaBusId = "PCI:0@1:0:0";
  };

  # Драйверы аппаратного ускорения видео для Intel UHD 630 (Coffee Lake)
  hardware.graphics = {
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      intel-vaapi-driver
    ];
  };

  # --- Звук: HP Pavilion, Intel HDA 8086:a348 (Cannon Lake) + ALC269 ---------
  #
  # Проблема: единственная ALSA-карта в системе — это HDMI-аудио NVIDIA
  # (/proc/asound/cards -> "HDA NVidia"). Контроллер Intel 0000:00:1f.3
  # захватывает sof-audio-pci-intel-cnl, и SOF не создаёт карту, поэтому
  # кодек Realtek ALC269 остаётся непривязанным — динамиков и микрофона нет.
  #
  # firmware тут ни при чём: intel/sof/sof-cnl.ri.zst и sof-hda-generic*.tplg
  # уже на месте. Не хватает топологии именно под эту плату (в sof-firmware
  # для CNL есть только sof-cnl-nocodec и sof-cnl-rt274), поэтому snd_soc_register_card
  # падает и карта не появляется.
  #
  # Параметр dmic_detect=0 САМ ПО СЕБЕ не помогает: он принадлежит модулю
  # snd_hda_intel, а на этом контроллере сидит sof-pci, и параметры hda_intel
  # до него не доходят. Перехват на SOF делает sound/hda/intel-dsp-config.c:
  #   FLAG_SOF_ONLY_IF_SOUNDWIRE && snd_intel_dsp_check_soundwire(pci) > 0
  #     -> "SoundWire enabled on CannonLake+ platform, using SOF driver"
  # Отдельной PCI-функции DMIC на ноутбуке тоже нет, так что DMIC тут не при чём.
  #
  # Поэтому отключаем SOF целиком — тогда 0000:00:1f.3 по модпробу занимает
  # snd_hda_intel, он находит ALC269, и появляется нормальная карта HDA Intel.
  # Побочный эффект (тот же, что даёт dsp_driver=1): цифровой микрофон-массив
  # на SoundWire перестаёт работать, остаётся аналоговый вход с ALC269.
  boot.blacklistedKernelModules = [
    "snd_sof_pci"
    "snd_sof_pci_intel_cnl"
  ];

  # Попадёт в limine.conf (cmdline:) автоматически — генератор читает
  # kernelParams из NixOS bootspec (nixos/modules/system/activation/bootspec.nix,
  # kernelParams = config.boot.kernelParams), limine-install.py кладёт их в
  # `cmdline:`. Руками конфиг загрузчика трогать не надо.
  #
  # На legacy-пути не даёт hda_intel пытаться поднять DMIC-массив.
  boot.kernelParams = [
    "snd_hda_intel.dmic_detect=0"
  ];

  # Перехват на legacy HDA задаётся через snd_intel_dspcfg: 0=auto, 1=legacy,
  # 2=SST, 3=SOF (MODULE_PARM_DESC в sound/hda/intel-dsp-config.c). Нам нужен 1.
  #
  # Имена модулей пишем с ПОДЧЁРКИВАНИЯМИ (snd_intel_dspcfg, snd_hda_intel) —
  # это их настоящие имена в /proc/modules; вариант с дефисами из некоторых
  # мануалов на модпробе не полагается.
  #
  # ВНИМАНИЕ: этот параметр — документальная страховка, а не основной рычаг.
  # Реально карту вернуло отключение SOF в boot.blacklistedKernelModules выше:
  # на момент применения dsp_driver=1 контроллер уже сидел на sof-pci, а решения
  # о выборе драйвера принимает intel-dsp-config.c, а не параметры hda_intel.
  # Оба механизма оставлены — они не конфликтуют, а blacklist уже проверен
  # вживую (карта HDA Intel PCH + Realtek ALC295 появились).
  boot.extraModprobeConfig = ''
    options snd_intel_dspcfg dsp_driver=1
    options snd_hda_intel dmic_detect=0
  '';

  # ── Планировщик и отзывчивость ОС ───────────────────────────────────────────
  #
  # Про governor: он уже НЕ здесь, а в services.auto-cpufreq ниже —
  # performance от сети, powersave от батареи. Дублировать его через
  # powerManagement.cpuFreqGovernor нельзя: auto-cpufreq перезаписывает
  # governor при каждом переключении питания, и статичное значение в
  # powerManagement его перебьёт, убив переключение на powersave.
  #
  # swappiness=10 — на десктопе с 8+ ГБ RAM подкачка почти не нужна, но
  # напористо свопить при нехватке памяти вредно: страницы процесса
  # (в т.ч. Qt-рендер quickshell) уходят на диск и возвращаются с задержкой,
  # что и выглядит как "микрофризы интерфейса".
  #
  # vfs_cache_pressure=50 (дефолт ядра 100) — держать больше dentry/inode
  # кэша: дешевле по памяти, зато быстрее повторные запуски программ и
  # разрешение путей в трейере/порталах.
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  # ── Firefox на dGPU (только этот хост) ─────────────────────────────────────
  # Внутренний экран (eDP-1) подключён к iGPU, поэтому сам компоновщик niri
  # перенести на NVIDIA нельзя, но тяжёлую растеризацию браузера — можно.
  #
  # Обёртка живёт здесь, а не в общем nixos/modules/software.nix, потому что
  # dgpu-offload создаётся в nixos/modules/nvidia.nix и существует только на
  # этом хосте. Fallback-ветка ниже оставлена как страховка на случай, если
  # карта в драйвере не поднимется: тогда firefox просто стартует на Intel.
  #
  # Собирается через symlinkJoin, а не wrapProgram: в этой ревизии nixpkgs
  # атрибут pkgs.wrapProgram отсутствует, а через wrapProgram нельзя было бы
  # сохранить desktop-файлы firefox — они лежат в том же пакете. Имя пакета
  # остаётся "firefox", чтобы в environment.systemPackages не появилось
  # двух записей с одним именем.
  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "firefox";
      paths = [ pkgs.firefox ];
      postBuild = ''
        rm $out/bin/firefox
        cat > $out/bin/firefox <<'EOF'
        #!/usr/bin/env bash
        if command -v dgpu-offload >/dev/null 2>&1; then
          exec dgpu-offload ${pkgs.firefox}/bin/firefox "$@"
        else
          exec ${pkgs.firefox}/bin/firefox "$@"
        fi
        EOF
        chmod +x $out/bin/firefox
      '';
    })
  ];

  # laptop-only hardware services; harmless on a desktop too
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "performance";
        turbo = "auto";
      };
      battery = {
        governor = "powersave";
        turbo = "never";
      };
    };
  };

  services.upower.enable = true;

  # laptop lid handling
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };
}
