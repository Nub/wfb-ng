{ lib, stdenv, fetchFromGitHub, kernel }:
stdenv.mkDerivation {
  pname = "rtl88xxau-aircrack";
  version = "${kernel.version}-unstable-02-05-2023";

  src = fetchFromGitHub {
    owner = "svpcom";
    repo = "rtl8812au";
    rev = "f1f447e2e184167b70bed4884534a2c27f4aa16e";
    hash = "sha256-0kHrNsTKRl/xTQpDkIOYqTtcHlytXhXX8h+6guvLmLI=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  hardeningDisable = [ "pic" ];

  prePatch = ''
    substituteInPlace ./Makefile \
      --replace /lib/modules/ "${kernel.dev}/lib/modules/" \
      --replace /sbin/depmod \# \
      --replace '$(MODDESTDIR)' "$out/lib/modules/${kernel.modDirVersion}/kernel/net/wireless/"
  '';

  preInstall = ''
    mkdir -p "$out/lib/modules/${kernel.modDirVersion}/kernel/net/wireless/"
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "wfb-ng kernel module for Realtek 88XXau network cards\n(8811au, 8812au, 8814au and 8821au chipsets) with monitor mode and injection support.";
    homepage = "https://github.com/svpcom/rtl8812au";
    license = licenses.gpl2Only;
    maintainers = [ maintainers.jethro ];
    platforms = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
  };
}
