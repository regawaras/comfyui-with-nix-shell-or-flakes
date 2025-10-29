# comfyui-with-nix-shell-or-flakes on Nvidia GPU
This repository provides a simple and reproducible way to run ComfyUI (https://github.com/comfyanonymous/ComfyUI) using Nix.

Requirements
Enabling Allow unfree
Adding CUDA and Nvidia to Global Nix Configuration on /etc/nixos/onfiguration.nix

```
 1   hardware.nvidia = {
    2     modesetting.enable = true;
    3     powerManagement.enable = true;
    4     powerManagement.finegrained = true;
    5     dynamicBoost.enable = false;
    6     nvidiaPersistenced = true;
    7     open = false; # use NVIDIA proprietary driver 
    8     nvidiaSettings = true;
    9     package = config.boot.kernelPackages.nvidiaPackages.stable;
   10     prime = {
   11       offload.enable = true; # Activate NVIDIA PRIME offloading
   12       offload.enableOffloadCmd = true; # activate command 'prime-run'
   13       intelBusId = "PCI:0:2:0"; # match it with your Intel GPU ID bus
   14       nvidiaBusId = "PCI:1:0:0"; # match it with your NVIDIA GPU ID bus
   15       sync.enable = false; # PRIME Synchronization (activate if there is tearing)
   16     };
   17   };
```

```
  1   environment.sessionVariables = {
   2     GBM_BACKEND = "nvidia-drm";
   3     NIXOS_OZONE_WL = "1";
   4     LIBVA_DRIVER_NAME = "nvidia";
   5     __GLX_VENDOR_LIBRARY_NAME = "nvidia";
   7     QT_QPA_PLATFORM = "wayland";
   9   };
   ```
