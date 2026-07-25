# NixOS module: out-of-tree driver for Realtek RTL8852CU / RTL8832CU USB
# Wi-Fi 6E adapters (morrownr's `8852cu`).
#
# Works for any USB dongle using these chipsets whose USB ID is in the
# driver's device table. Reference/tested device:
#
#   MSI AXE5400 - USB ID 0db0:991d ("802.11ax WLAN Adapter"), RTL8852CU.
#
# Scope: USB adapters only. The PCIe RTL8852CE and SDIO variants are NOT
# handled here - those use mainline `rtw89`.
#
# Mainline `rtw89` only gains 8852CU (USB) support in kernel 6.19+, so on
# older kernels we build morrownr's out-of-tree driver against the running
# kernel and load it at boot.
#
# Usage - flake:
#   imports = [ inputs.rtl8852cu-nixos.nixosModules.default ];
#   hardware.rtl8852cu.enable = true;
#
# Usage - plain import (channels):
#   imports = [ ./rtl8852cu.nix ];
#   hardware.rtl8852cu.enable = true;

{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.rtl8852cu;

  # Build the module against whatever kernel the system currently uses.
  rtl8852cu = config.boot.kernelPackages.callPackage (
    { stdenv, lib, fetchFromGitHub, kernel, bc, nukeReferences }:

    stdenv.mkDerivation {
      pname = "rtl8852cu";
      version = "${kernel.version}-unstable-2025-11-13";

      src = fetchFromGitHub {
        owner = "morrownr";
        repo = "rtl8852cu-20251113";
        rev = "1530c38e5b1be6d1e96a31cf4f3602a9c23f2465";
        hash = "sha256-gYmmpiBD0GuUfDg9MZQEuFE9zeIA67hUi/8thhdbVWE=";
      };

      nativeBuildInputs = [ bc nukeReferences ] ++ kernel.moduleBuildDependencies;

      hardeningDisable = [ "pic" "format" ];

      # depmod runs against /lib/modules on the live system; not valid inside
      # the build sandbox, so comment it out. NixOS regenerates modules.dep.
      postPatch = ''
        substituteInPlace ./Makefile --replace-fail /sbin/depmod \#
      '';

      # Command-line assignments override the Makefile/platform *.mk defaults,
      # so we can point KSRC/MODDESTDIR at the sandboxed kernel + $out.
      makeFlags = [
        "ARCH=${stdenv.hostPlatform.linuxArch}"
        "KVER=${kernel.modDirVersion}"
        "KSRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
        "MODDESTDIR=${placeholder "out"}/lib/modules/${kernel.modDirVersion}/kernel/net/wireless/"
        "CONFIG_PLATFORM_I386_PC=y"
        "CONFIG_PLATFORM_ARM_RPI=n"
      ];

      env.NIX_CFLAGS_COMPILE = "-Wno-designated-init";

      preInstall = ''
        mkdir -p "$out/lib/modules/${kernel.modDirVersion}/kernel/net/wireless/"
      '';

      # Strip references to the huge kernel.dev build tree so it isn't a runtime dep.
      postInstall = ''
        nuke-refs $out/lib/modules/*/kernel/net/wireless/*.ko
      '';

      enableParallelBuilding = true;

      meta = {
        description = "Realtek RTL8852CU/RTL8832CU USB Wi-Fi driver (morrownr)";
        homepage = "https://github.com/morrownr/rtl8852cu-20251113";
        license = lib.licenses.gpl2Only;
        platforms = [ "x86_64-linux" ];
      };
    }
  ) {};
in
{
  options.hardware.rtl8852cu.enable =
    lib.mkEnableOption "the out-of-tree Realtek RTL8852CU/RTL8832CU USB Wi-Fi driver (morrownr)";

  config = lib.mkIf cfg.enable {
    # Make the compiled 8852cu.ko available to this kernel...
    boot.extraModulePackages = [ rtl8852cu ];
    # ...and load it (udev also auto-loads it on plug for any USB ID in the
    # driver's device table).
    boot.kernelModules = [ "8852cu" ];
  };
}
