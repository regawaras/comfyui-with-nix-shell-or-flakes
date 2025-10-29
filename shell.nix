# shell.nix

{ pkgs ? import <nixpkgs> {
    config = {
      # Mengizinkan paket berpemilik (unfree).
      allowUnfree = true;
    };
  }
}:

pkgs.mkShell {
  # Dependensi yang diperlukan
  buildInputs = [
    pkgs.python312          # Python
    pkgs.stdenv.cc.cc.lib   # libstdc++.so.6

    # --- PERBAIKAN: Gunakan paket NVIDIA yang benar untuk buildInputs ---
    # Tambahkan paket yang menyediakan biner driver yang diperlukan oleh PyTorch
    pkgs.linuxPackages.nvidia_x11 # Menyediakan utilitas dan shared libs driver

    # Ganti pkgs.cudatoolkit dengan paket CUDA lengkap untuk lingkungan shell
    pkgs.cudaPackages.cudatoolkit # Pustaka runtime CUDA
    pkgs.cudaPackages.cudnn       # Pustaka Deep Learning yang sering diperlukan
    
    pkgs.git
  ];

  # Hook yang dijalankan saat shell dimulai
  shellHook = ''
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ 
      pkgs.stdenv.cc.cc.lib
      pkgs.cudaPackages.cudatoolkit
      pkgs.cudaPackages.cudnn
      pkgs.linuxPackages.nvidia_x11 
    ]}:$LD_LIBRARY_PATH"
  '';
}
