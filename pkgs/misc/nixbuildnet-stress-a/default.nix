{
  parallel,
  runCommand,
  stress-ng,
  writeShellApplication,
  # Output files
  outFilesSizeMiB ? 1,
  numberOfTmpFiles ? 3,
  numberOfOutFiles ? 2,
  # CPU/MEM/IO stress
  stressDurationSeconds ? 10,
  cpuLoad ? 2,
  memLoadCpus ? 2,
  memLoadBytes ? 0.1 * 1024 * 1024 * 1024,
  ioLoad ? 2,
  hddLoad ? 2,
  # change this to cause a fresh build
  version ? "1.0.0",
}:

let
  make-stress = writeShellApplication {
    name = "make-stress";
    runtimeInputs = [
      stress-ng
    ];
    text = ''
      echo Causing stress:
      STRESS_TMP_PATH=''${STRESS_TMP_PATH:-./make-stress-workdir}
      set -x
      mkdir -p "$STRESS_TMP_PATH"
      stress-ng \
        --matrix ${toString cpuLoad} \
        --vm 2 \
        --vm-bytes ${toString memLoadBytes} \
        --iomix ${toString ioLoad} \
        --hdd ${toString hddLoad} \
        --temp-path "$STRESS_TMP_PATH" \
        --timeout ${toString stressDurationSeconds}
    '';
  };

  make-files = writeShellApplication {
    name = "make-files";
    runtimeInputs = [
      parallel
    ];
    text = ''
      echo Creating files:

      if [ -z "$out" ]; then
        echo Output directory not specified.
        exit 1
      fi

      if [ -z "$NIX_BUILD_CORES" ]; then
        echo Build cores not set.
        exit 1
      fi

      set -x
      parallel -j "$NIX_BUILD_CORES" "dd if=/dev/urandom of=stress-a-result-{} bs=1M count=${toString outFilesSizeMiB}" ::: $(seq ${toString (numberOfOutFiles + numberOfTmpFiles)})
      mkdir "$out"
      mkdir -p "$out/stress-a"

      echo Moving files into output location:
      for i in $(seq ${toString numberOfOutFiles}); do
        mv "stress-a-result-$i" "$out/stress-a/"
      done
    '';
  };

in runCommand "stress-a" {
  nativeBuildInputs = [
    make-files
    make-stress
    parallel
  ];
} ''
  echo Version: ${version}
  echo Cores: $NIX_BUILD_CORES
  parallel --color --tag --line-buffer ::: make-stress make-files
''
