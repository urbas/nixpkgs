{ lib, stdenv, fetchFromGitHub, libusb1 }:

stdenv.mkDerivation {
  pname = "rpiboot";
  version = "unstable-2021-01-18";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "usbboot";
    rev = "49a2a4f22eec755b8c0377b20a5ecbfee089643e";
    sha256 = "0db0slq0m56kkr363wdpzrncsw5w34jaxz8c2c9wdr8xa6m05a93";
  };

  nativeBuildInputs = [ libusb1 ];

  patchPhase = ''
    sed -i "s@/usr/@$out/@g" main.c
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/rpiboot
    cp rpiboot $out/bin
    cp -r msd $out/share/rpiboot
  '';

  meta = with lib; {
    homepage = "https://github.com/raspberrypi/usbboot";
    description = "Utility to boot a Raspberry Pi CM/CM3/Zero over USB";
    license = licenses.asl20;
    maintainers = with maintainers; [ cartr ];
    platforms = [ "aarch64-linux" "armv7l-linux" "armv6l-linux" "x86_64-linux" ];
  };
}
