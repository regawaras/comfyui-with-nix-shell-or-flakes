{ pkgs ? import <nixpkgs> {
    config = {
      # Allow proprietary (unfree) packages.
      allowUnfree = true;
    };
  }
}:

pkgs.mkShell {
  # Required dependencies
  buildInputs = [
    pkgs.python312          # Python
    pkgs.stdenv.cc.cc.lib   # libstdc++.so.6

    # --- FIX: Use the correct NVIDIA packages for buildInputs ---
    # Add packages that provide the necessary driver binaries for PyTorch
    pkgs.linuxPackages.nvidia_x11 # Provides driver utilities and shared libs

    # Replace pkgs.cudatoolkit with the full CUDA package for the shell environment
    pkgs.cudaPackages.cudatoolkit # CUDA runtime libraries
    pkgs.cudaPackages.cudnn       # Deep Learning library often required
    
    pkgs.git
  ];

  # Hook executed when the shell starts
  shellHook = ''
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ 
      pkgs.stdenv.cc.cc.lib
      pkgs.cudaPackages.cudatoolkit
      pkgs.cudaPackages.cudnn
      pkgs.linuxPackages.nvidia_x11 
    ]}:$LD_LIBRARY_PATH"
  '';
}
