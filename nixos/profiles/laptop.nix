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
