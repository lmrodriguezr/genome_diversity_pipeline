#!/bin/bash

if [[ $GDIV_ENV != 4 ]] ; then

  # Covered by conda - No longer needed
  #module load idba/1.1.1_kMSS
  #module load R/3.6.0
  #module load bowtie2/2.3.2
  #module load hmmer/3.1b1
  #module load open64/4.5.2
  #module load gnuparallel/20180822

  # Server dependent module.
  # Need conda loaded with miniconda or anaconda
  module purge 
  module load anaconda3/2019.03 &>/dev/null

  ###############################################################################
  # Sever dependent - need link to servers conda install of genome div yaml
  shared3="/storage/coda1/p-ktk3/0/shared/rich_project_bio-konstantinidis/shared3"
  conda_env_path="$shared3/conda_envs/genome_diversity"
  if [[ ! -d "$HOME/.conda/envs/genome_diversity" ]] ; then
    GDIV_CONDA=${GDIV_CONDA:-"$conda_env_path"}
    mkdir -p "$HOME/.conda/envs"
    ln -s "$GDIV_CONDA" "$HOME/.conda/envs/genome_diversity"
  fi
  source activate genome_diversity

  ##############################################################################
  # I think we should just have this as a requirement for users to have
  # in there path. Makes it easier to transfer pipeline to a different
  # server right?
  #shared3="$HOME/shared3"
  # added Phoenix absolute path above
  # Add standard group tools to the path
  #export PATH="$shared3/miga/bin:$PATH"
  #export PATH="$shared3/apps/enveomics/Scripts:$shared3/bin:$PATH"
  ##############################################################################
  
  # Add Roth's FastA scripts to the path
  #export PATH="$shared3/apps/rotheconrad_scripts/Fasta:$PATH"
  # changed this to use the one script included with the git hub
  # repository. Should be easier to transfer to other servers
  # get the link to this script
  scr=$(readlink -f "$0" 2>/dev/null)
  # get the directory this script is stored in
  pkg=$(dirname "$scr")
  export PATH="$pkg/scripts:$PATH"

  # environment loaded. update environmental variable
  export GDIV_ENV=4
fi

