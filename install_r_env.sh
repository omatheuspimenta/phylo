#!/usr/bin/env bash
set -e  # Stop if error

# Init conda (if do not before)
source "$HOME/miniconda3/etc/profile.d/conda.sh"

# Update conda before install mamba
conda update -n base -c defaults conda -y

# Install mamba in base env
conda install -n base -c conda-forge mamba -y

# Create R env
mamba create -n R -c conda-forge r-base -y

# Activate R env
conda activate R

# Install essential r packages
mamba install -c conda-forge r-essentials -y

# Run install_reqs.R
Rscript install_reqs.R
