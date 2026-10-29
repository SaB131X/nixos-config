# hosts/laptop/hardware-extras.nix
{ lib, config, pkgs, ... }:

{
  hardware.nvidia = {
    prime = {
      # Bus IDs (Change these to match your `lspci` output!)
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}