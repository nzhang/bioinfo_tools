# Running scSplit with latest python
This is based on the open source https://github.com/jon-xu/scSplit, whose latest update was in 2023. Since then python packages were updated significantly so that the scSplit tool is not working out of the box. This repo is to fix some of the incompatibility issues. 

## Setup software dependencies
There are two sets of software dependencies for scSplit: binary tools and python packages.

The necessary binary tools are listed in setup.sh and you can run these for macOS.

The python packages are listed in pyprojects.toml, and we can set it up using uv. Instructions on how to setup uv and manage python packages are also listed in setup.sh.

You can also download test dataset instructed by in the setup.sh.

## Running scSplit
Steps and commands on how to run scSplit is documented in the run.sh file. You should run them after setup.sh.

All these commands are fairly efficient except freebayes. For the full dataset it is better to run freebayes using the parallel version. Since freebayes doesn't have the parallel version on macOS via brew install, I include the script `fasta_generate_regions.py` and leverage the parallel command to manually separate the full dataset into smaller subset and run freebayes on the subsets in parallel. With 10 threads on my MacBook Pro M3, it took ~3 hours to finish.
