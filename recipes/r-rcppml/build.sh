#!/bin/bash
set -euo pipefail

# The GPU bridge is CUDA, so it is a Linux-only step. Everywhere else this is a
# plain CPU build: configure(1) finds no nvcc, sets cuda_found=no in
# inst/build_config, and every CPU solver (lanczos, krylov, irlba, randomized,
# deflation) still works. gpu_available() then returns FALSE.
if [[ "$(uname)" == "Linux" ]]; then
  # configure(1) sniffs $CUDA_HOME/bin/nvcc to decide cuda_found in inst/build_config.
  export CUDA_HOME="${BUILD_PREFIX}"

  # Upstream's default arch list (V100 / RTX 8000 / A100 / H100 + sm_90 PTX).
  # cubins are minor-version compatible, so sm_80 also covers 8.6 and 8.9.
  CUDA_ARCH="${CUDA_ARCH:--gencode arch=compute_70,code=sm_70 \
   -gencode arch=compute_75,code=sm_75 \
   -gencode arch=compute_80,code=sm_80 \
   -gencode arch=compute_90,code=sm_90 \
   -gencode arch=compute_90,code=compute_90}"

  # The GPU bridge is a separate nvcc build, deliberately outside R's build system
  # (see src/Makefile.gpu). It must land in inst/lib BEFORE R CMD INSTALL, which is
  # what copies inst/ into the installed package — that is where .find_gpu_lib()
  # looks (system.file("lib", "RcppML_gpu.so")).
  make -C src -f Makefile.gpu install \
    CUDA_ARCH="${CUDA_ARCH}" \
    EIGEN_INC="$("${PREFIX}/bin/Rscript" -e 'cat(system.file("include", package="RcppEigen"))')" \
    LIBS="-L${PREFIX}/lib -L${PREFIX}/lib/stubs -lcublas -lcusparse -lcusolver -lcuda"

  # ...and only there: R CMD INSTALL sweeps any stray .so in src/ into libs/,
  # which would ship a second 7 MB copy that nothing loads.
  rm -f src/RcppML_gpu.so src/*.o
fi

# the GitHub archive does not preserve the exec bit
chmod +x configure cleanup

R CMD INSTALL --build .
