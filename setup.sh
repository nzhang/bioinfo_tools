# 1 Install necessary tools
# For Mac
brew install samtools freebayes vcftools parallel bcftools
# For Linux, the easiest way is to install MiniConda first and then install BioConda
# Download the MinoConda shell from /docs/getting-started/miniconda/install#macos-linux-installation:to-download-a-different-version
# Then add download channels to minoconda:
#     conda config --add channels conda-forge
#     conda config --add channels bioconda
#     conda config --set channel_priority strict
#
# Then conda install all the tools mentioned above.
#     conda install samtools freebayes vcftools parallel bcftools

# 2. Setup uv for python virtual environment management
curl -LsSf https://astral.sh/uv/install.sh | sh

# 3. Install dependent python packages using uv
#    This will install all dependencies listed in pyprojects.toml.
# After this you can run
#     `source .venv/bin/activate`
# to activate the virtual environment for your project.
uv sync

# 4. Download human gnomes
# There are 2 formats. Below download the ensembl format only.
# Download Ensembl GRCh38 (approx 800MB compressed)

curl -O http://ftp.ensembl.org/pub/release-110/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
gunzip Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
# Generate the index file for the FASTA file.
samtools faidx Homo_sapiens.GRCh38.dna.primary_assembly.fa
