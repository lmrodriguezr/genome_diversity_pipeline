#!/bin/bash

target=$1

if [[ ! -n $target ]] ; then
  echo "Usage: $0 target_folder
  target_folder: Path to the target folder to create
  "
  exit 0
fi

mkdir -p "$target"
cd "$target"
mkdir -p 01_reads 02_trim 03_norm \
  04_asm 06_maxbin 07_metabat 08_derep 09_mapping 10_coverage \
  xx_log xx_summary

