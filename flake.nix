  
description = "Nix-powered development shell for ComfyUI with NVIDIA/CUDA support.";                    
                                                                                                                
        inputs = {                                                                                             
          # Pin to a specific Nixpkgs channel for better reproducibility.                                    
          # You can change "nixos-23.11" to "nixos-unstable" for the latest packages,                         
          # or another stable channel like "nixos-24.05".                                                       
          nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";                                                    
        };                                                                                                    
                                                                                                              
       outputs = { self, nixpkgs }:                                                                          
        let                                                                                                   
           system = "x86_64-linux"; # Assuming Linux for NVIDIA/CUDA                                           
           pkgs = import nixpkgs {                                                                             
             inherit system;                                                                                   
             config = {                                                                                        
               allowUnfree = true;                                                                             
               cudaSupport = true; # Explicitly enable cudaSupport for pkgs                                    
             };                                                                                                
           };                                                                                                  
         in {                                                                                                  
           devShells.${system}.default = pkgs.mkShell {                                                        
             buildInputs = [                                                                                   
               pkgs.python312                                                                                  
               pkgs.stdenv.cc.cc.lib                                                                           
               pkgs.linuxPackages.nvidia_x11                                                                   
               pkgs.cudaPackages.cudatoolkit                                                                   
               pkgs.cudaPackages.cudnn                                                                         
               pkgs.git                                                                                        
             ];                                                                                                
                                                                                                               
             shellHook = ''                                                                                    
               export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [                                            
                 pkgs.stdenv.cc.cc.lib                                                                         
                 pkgs.cudaPackages.cudatoolkit                                                                 
                 pkgs.cudaPackages.cudnn                                                                       
                 pkgs.linuxPackages.nvidia_x11                                                                 
               ]}:$LD_LIBRARY_PATH"                                                                            
                                                                                                               
               echo "Welcome to the ComfyUI development shell!"                                                
               echo "Python 3.12, CUDA, and NVIDIA drivers are available."                                     
               echo "Remember to activate your Python venv and install ComfyUI dependencies."                  
             '';                                                                                               
           };                                                                                                  
        };                                                                                                    
     }           
