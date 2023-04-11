#!/bin/bash
#SBATCH --partition=qinferno
#SBATCH -A gts-ktk3-coda20

# Variables:
# - $PKG: Full path to the package location
# - $TARGET: Path to the target location (could be relative)
# - $DATASET: Name of the dataset to process
# - $STEP: Step code to run within the package
# - $RAM (optional): RAM limit for the software called
# - $USE_FRACTION (optional): Fraction of the input reads to use

cd "$SLURM_SUBMIT_DIR"
RAM="$RAM" USE_FRACTION="$USE_FRACTION" "$PKG/${STEP}.bash" "$TARGET" "$DATASET"

