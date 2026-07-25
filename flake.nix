{
  description = "Realtek RTL8852CU/RTL8832CU USB Wi-Fi driver as a NixOS module";

  outputs = { self }: {
    nixosModules.default = ./rtl8852cu.nix;
    nixosModules.rtl8852cu = ./rtl8852cu.nix;
  };
}
