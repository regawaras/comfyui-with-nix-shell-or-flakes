# comfyui-with-nix-shell-or-flakes on Nvidia GPU

This repository provides a simple and reproducible way to run ComfyUI (https://github.com/comfyanonymous/ComfyUI) using Nix. Say goodbye to the hassle of manually installing complex dependencies like Python, PyTorch, CUDA, and the correct NVIDIA drivers.

## GPU Compatibility and CUDA Version
For ComfyUI to effectively utilize your NVIDIA GPU, it's crucial that your GPU's compute capability (often referred to as sm_XX) is compatible with the CUDA Toolkit version provided by this Nix environment.

This repository's shell.nix (and flake.nix) is configured to use the default stable CUDA Toolkit version available in  Nixpkgs. While Nix handles the installation of the CUDA Toolkit, you should verify your GPU's compatibility.

## How to Check Your GPU's Compute Capability (sm_XX)?
You can find your GPU's compute capability using one of the following methods:
1. Using `nvidia-smi` (if NVIDIA drivers are installed on your host system):
```
nvidia-smi --query-gpu=compute_cap --format=csv,noheader
```
This will output a value like 8.6 (which corresponds to sm_86).

2. Referencing NVIDIA's CUDA GPUs page:
Visit NVIDIA's CUDA GPUs page (https://developer.nvidia.com/cuda-gpus) and find your GPU model to see its compute capability.

## Compatibility Check  
Once you know your GPU's sm_XX value, ensure it is supported by the CUDA Toolkit version provided by Nixpkgs. Generally, newer CUDA versions support a wide range of older GPUs, but very old GPUs might not be supported by the latest CUDA.

If you require a specific CUDA Toolkit version not provided by default, advanced users can modify the shell.nix (or flake.nix) to specify a different cudaPackages derivation (e.g., pkgs.cudaPackages_11_8.cudatoolkit for CUDA 11.8).

## Requirements for NixOS Global Configuration

  ### 1.1. General Nixpkgs Settings
  Ensure that Nixpkgs allows "unfree" (proprietary) packages and globally enables CUDA support. NVIDIA drivers fall under
  the "unfree" category.

```
    nixpkgs.config.cudaSupport = true;
    nixpkgs.config.allowUnfree = true;
```

  ### 1.2. Kernel Modules and Boot Parameters
  These settings ensure that NVIDIA kernel modules are loaded at boot and enable modesetting for the NVIDIA driver, which
  is crucial for Wayland and optimal performance.

```
    boot.initrd.kernelModules = [ "nvidia" "i915" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    boot.kernelParams = [ "nvidia-drm.modeset=1" ];
```

  ### 1.3. Graphics Hardware Configuration
  This section enables graphics support and explicitly specifies the NVIDIA driver package to be used.
```
    hardware.graphics = {
      enable = true;
      extraPackages = with config.boot.kernelPackages; [
      nvidiaPackages.stable
      ];
    };
   ```
  ### 1.4. NVIDIA Driver Configuration
  The hardware.nvidia block is the most critical part for configuring the NVIDIA driver. It includes settings for
  modesetting, power management, nvidiaPersistenced, and notably, PRIME offloading configuration for laptops with dual
  GPUs (Intel + NVIDIA).

```
    hardware.nvidia = {
     modesetting.enable = true;
     powerManagement.enable = true;
     powerManagement.finegrained = true;
     dynamicBoost.enable = false;
     nvidiaPersistenced = true;
     open = false; # use NVIDIA proprietary driver 
     nvidiaSettings = true;
     package = config.boot.kernelPackages.nvidiaPackages.stable;
        prime = {
          offload.enable = true; # Activate NVIDIA PRIME offloading
          offload.enableOffloadCmd = true; # activate command 'prime-run'
          intelBusId = "PCI:0:2:0"; # match it with your Intel GPU ID bus
          nvidiaBusId = "PCI:1:0:0"; # match it with your NVIDIA GPU ID bus
          sync.enable = false; # PRIME Synchronization (activate if there is tearing)
        };
      };
```

  ### 1.5. Additional System Packages
  Ensure that cudatoolkit, cudnn, and nvidia-vaapi-driver are available system-wide. These are important for applications
  that directly require these libraries or for video acceleration.

```
  environment.systemPackages = with pkgs; [
    # ... other packages ...
    pkgs.cudatoolkit
    cudaPackages.cudnn
    mesa-demos # Provides glxinfo
    vulkan-tools # Provides vulkaninfo for Vulkan
    clinfo
    nvidia-vaapi-driver
    # ... other packages ...
  ];
   ```

  ### 1.6. Environment Variables for Wayland & NVIDIA

  These environment variables are crucial for NVIDIA to function correctly in a Wayland environment (especially
  Hyprland), ensuring applications use the correct drivers and avoiding compatibility issues.

```
  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    NIXOS_OZONE_WL = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    QT_QPA_PLATFORM = "wayland";
  };
```

  1.7. NVIDIA Container Toolkit Support
  If you plan to use Docker or Podman with NVIDIA GPU acceleration, this section enables the nvidia-container-toolkit.

```
  hardware.nvidia-container-toolkit.enable = true;
```
## Nix Shell Environment for ComfyUI with NVIDIA/CUDA Support
This shell.nix file defines a self-contained and reproducible development environment specifically tailored for running ComfyUI (https://github.com/comfyanonymous/ComfyUI) on systems with NVIDIA GPUs. It significantly simplifies the setup process by providing all necessary dependencies—Python, NVIDIA driver components, CUDA Toolkit, and cuDNN—without requiring system-wide installations that might conflict with other software.

The primary goal of this shell.nix is to create an isolated environment where ComfyUI can run seamlessly, leveraging your NVIDIA GPU for accelerated computations, without the typical hassle of manually managing complex dependencies.

Key Components and Their Role

  1. Environment Definition (pkgs and allowUnfree)
```
  { pkgs ? import <nixpkgs> {
      config = {
        allowUnfree = true;
      };
    }
  }:
```
This block initializes the Nix package set (pkgs). The allowUnfree = true; configuration is crucial here because proprietary NVIDIA drivers and CUDA components are considered "unfree" by Nixpkgs, and this setting permits their inclusion in the environment.

  2. Core Dependencies (buildInputs)

```
    buildInputs = [
      pkgs.python312          # Python
      pkgs.stdenv.cc.cc.lib   # libstdc++.so.6
      pkgs.linuxPackages.nvidia_x11 # Provides NVIDIA driver shared libraries
      pkgs.cudaPackages.cudatoolkit # CUDA runtime libraries
      pkgs.cudaPackages.cudnn       # cuDNN library for deep learning acceleration
      pkgs.git
    ];
```
  The buildInputs array lists all the packages that will be made available in the shell environment.
   * `pkgs.python312`: Specifies the exact Python version (3.12) required for ComfyUI.
   * `pkgs.stdenv.cc.cc.lib`: Essential C/C++ standard libraries, often required by native Python extensions.
   * `pkgs.linuxPackages.nvidia_x11`: Provides the necessary shared libraries for the NVIDIA driver, allowing applications
     to interact with the GPU.
   * `pkgs.cudaPackages.cudatoolkit`: The CUDA runtime library, which is fundamental for GPU-accelerated computations used
     by PyTorch (ComfyUI's backend).
   * `pkgs.cudaPackages.cudnn`: The NVIDIA cuDNN library, specifically designed to accelerate deep learning operations.
   * `pkgs.git`: Included for version control operations, potentially for cloning ComfyUI itself or its custom extensions.

  3. Runtime Configuration (shellHook)
```
    shellHook = ''
      export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.cudaPackages.cudatoolkit
        pkgs.cudaPackages.cudnn
        pkgs.linuxPackages.nvidia_x11
      ]}:$LD_LIBRARY_PATH"
    '';
```
The shellHook executes commands every time you enter the nix-shell. This specific hook is vital: it sets the LD_LIBRARY_PATH environment variable. This ensures that the Python environment (and PyTorch within it) can correctly locate and link against the NVIDIA and CUDA shared libraries provided by Nix at runtime. Without this, applications might fail to detect or utilize the GPU.

  How to Use
   1. Navigate to the directory containing this shell.nix file:
```
cd /path/to/your/repo/als/comfyui/ComfyUI
```
   2. Enter the shell environment:
```
nix-shell
```
This command will download and set up all the specified dependencies. This process might take some time during the initial run.

   4. Once inside the shell, you can proceed with ComfyUI's installation steps (e.g., creating a Python virtual environment,
      installing requirements.txt, and running main.py).

ComfyUI Python Setup (within the Nix shell)
Similar to the Flakes method, using a venv is recommended for managing ComfyUI's Python dependencies.

First, ensure you are in the ComfyUI project root directory (e.g., als/comfyui/ComfyUI).
Ensure pip is available and up-to-date within the Nix environment
```
python -m ensurepip --upgrade
```    
# Create and activate a Python virtual environment         
```
python -m venv venv
```
activate the Python Virtual Environments
```       
 source venv/bin/activate
```

IMPORTANT: Install PyTorch with the correct CUDA version for your GPU. The 'cuXXX' part in the --index-url must match the CUDA version provided by your Nix shell. You can check the CUDA version available in your Nix shell by running 'nvcc --version' after entering the shell. Ensure the PyTorch version is compatible with ComfyUI and your GPU's compute capability (sm_XX). Example for a GPU compatible with CUDA 11.8 (e.g., sm_61, sm_70, sm_75, sm_80, sm_86, sm_89, sm_90):

```
pip install torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 --index-url https://download.pytorch.org/whl/cu118
```  
### Install other ComfyUI requirements
```
pip install -r requirements.txt
```

### Run ComfyUI
Note: To run ComfyUI, you must first enter the Nix shell (nix-shell) and then activate your Python virtual environment 
```
source venv/bin/activate)
```
and then 
```
python main.py
```
