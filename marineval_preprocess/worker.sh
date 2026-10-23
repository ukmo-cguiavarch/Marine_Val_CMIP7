#!/bin/bash -l
set -eo pipefail
# Edit these two lines if your site uses a different environment.
module load scitools
conda activate marval
set -u
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
exec python "$1" worker "$2" "$3" "$4" "${SLURM_ARRAY_TASK_ID:?Missing array index}"
