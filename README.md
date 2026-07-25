# rtl8852cu-nixos

A NixOS module that builds and loads morrownr's out-of-tree **RTL8852CU /
RTL8832CU** driver for **USB Wi-Fi 6E** adapters.

- **Chipsets:** Realtek RTL8852CU, RTL8832CU (Wi-Fi 6E, **USB only**)
- **Reference/tested device:** MSI AXE5400 - USB ID `0db0:991d`
- **Platforms:** `x86_64-linux`

Works for any USB dongle on these chipsets whose USB ID is in the
[morrownr/rtl8852cu-20251113](https://github.com/morrownr/rtl8852cu-20251113)
device table. Mainline `rtw89` only gains 8852CU (USB) support in kernel 6.19+,
so on older kernels this module compiles the driver against your running kernel
and loads it at boot.

> **Not** for the PCIe `RTL8852CE` or SDIO variants - those use mainline `rtw89`.

## Usage

The module is **opt-in**: importing it does nothing until you set
`hardware.rtl8852cu.enable = true;`.

### Flakes

```nix
{
  inputs.rtl8852cu-nixos.url = "github:kubastick/rtl8852cu-nixos";

  outputs = { nixpkgs, rtl8852cu-nixos, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        rtl8852cu-nixos.nixosModules.default
        { hardware.rtl8852cu.enable = true; }
        ./configuration.nix
      ];
    };
  };
}
```

### Channels / plain config - remote import (no flakes)

A non-flake `configuration.nix` can import the module straight from GitHub with
`builtins.fetchTarball` - no need to copy any files:

```nix
let
  rtl8852cu-nixos = builtins.fetchTarball {
    # TODO: Update hashes once published
    url    = "https://github.com/kubastick/rtl8852cu-nixos/archive/<commit-or-tag>.tar.gz";
    sha256 = "";
  };
in {
  imports = [ "${rtl8852cu-nixos}/rtl8852cu.nix" ];
  hardware.rtl8852cu.enable = true;
}
```

### Channels / plain config - vendored copy

Or copy `rtl8852cu.nix` into your config tree and import it locally:

```nix
imports = [ ./rtl8852cu.nix ];
hardware.rtl8852cu.enable = true;
```

## My device isn't detected

If your dongle uses an 8852CU/8832CU chipset but its USB ID isn't in the driver's
table, it won't auto-bind. Check the chipset with `lsusb`, then add your ID
upstream (`new_id` / the driver's device table) - open an issue upstream if it's
a legitimately new rebrand.

## Updating the driver

When morrownr publishes a newer snapshot, bump `owner`/`repo`/`rev` in
`rtl8852cu.nix` and refresh the `hash`:

```sh
nix-prefetch-github morrownr rtl8852cu-YYYYMMDD --rev <commit>
```

## License

The driver upstream is GPL-2.0-only; this packaging follows suit.
