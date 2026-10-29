# Nix repo ![Nix](https://img.shields.io/badge/NIX-5277C3.svg?style=flat-square&logo=NixOS&logoColor=white) [![Nix Checks](https://github.com/SaB131X/nixos-config/actions/workflows/main.yml/badge.svg)](https://github.com/SaB131X/nixos-config/actions/workflows/main.yml) 
## About
That's the part of the system which i'm fine to expose to the people. Mostly it's my simple setup for my laptop and the wsl but later i'll add configs for network devices as well.
## Structure
That repo follows basic multi host flake design with separate host and modules directories.  
- `flake.nix` - declares how hosts are being assembled from modules and some tests for CI.
- `flake.lock` - list of used packages and their versions (auto generated on `sudo nix flake update --flake .`).
- hosts [dir] - contains `default.nix` and `hardware-configuration.nix` (if any) files for each host (physical machine). 
- modules [dir] - contains `default.nix` files for speciefic modules (parts) of hosts.
- scripts [dir] - contains useful scripts for CI or daily use.
## Accessible Modules
You can access most modules from that repo by adding it to the flake inputs `inputs = { sbxflake.url ="github:SaB131X/nixos-config";}` and then referencing it in nixosConfigurations of the flake `modules [sbxflake.nixosModules.kde];` or Configuration.nix file `imports = [inputs.sbxflake.nixosModules.kde];` and then using `kde.audio.enable = true` in your own modules.
## PS
I don't plan on using flake-parts or something bizzare for now so you may use it if you just start your way in nix as an example and improve it with crazy community libs later.
