#!/usr/bin/env bash
set -e  # Stop if error

# Init conda (if do not before)
source "$HOME/miniconda3/etc/profile.d/conda.sh"

# Install packages
sudo apt install liblapack-dev libblas-dev gfortran libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev libwebp-dev -y

# Update conda before install mamba
conda update -n base -c defaults conda -y

# Install mamba in base env
conda install -n base -c conda-forge mamba -y

# Create R env
mamba create -n R4 -c conda-forge -c bioconda r-essentials r-base==4.4 bioconductor-ggtree numpy -y

# Activate R env
conda activate R4

# Install essential r packages
#mamba install -c conda-forge r-essentials -y

# Run install_reqs.R
Rscript install_reqs.R
