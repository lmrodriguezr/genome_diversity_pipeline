# genome diversity pipeline

#### To Setup:

Navigate to preferred install directory and use:

```bash
git clone https://github.com/lmrodriguezr/genome_diversity_pipeline.git
```

1. *MiGA must be installed and available in PATH: https://manual.microbial-genomes.org/ ... On GATECH PACE server, if you have not previously done so, run: ~/shared-p/miga-conf/init.bash*
2. *Enveomics package must be installed and available in PATH: http://enve-omics.ce.gatech.edu/enveomics/download*
3. *Adjust the maximum RAM available lines 47-50 in 00_launcher.bash*
4. *Adjust conda module in line 8 of 00_env.bash*

##### Conda environment installation

To Create new conda environment using conda.yml file

```bash
conda env create --prefix /path_to/shared/conda_envs -f genome_diversity_pipeline/conda.yml
```

*conda environment should only need to be installed once per server*
*Update shared3 and conda_env_path variable lines 21 and 22 in 00_env.bash*

#### To add a dataset:

```bash

/path/to/pkg/01_add.bash target_dir dataset_name /path/to/reads.[12].fastq.gz

```

This will automatically copy and launch the pipeline step by step.

*fastq files should be gzipped.*

#### If you want to continue a halted run:

*Delete the directory of the halted step ???*

```bash

/path/to/pkg/xx_runme.bash target_dir dataset_name

```

This will detect the last complete step and lanch the next one.