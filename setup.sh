# 1 Install necessary tools
brew install samtools freebayes vcftools parallel bcftools

# 2. Setup uv for python virtual environment management
curl -LsSf https://astral.sh/uv/install.sh | sh

# 3. Install dependent python packages using uv
# cd your project root directory before running `uv init`
# After this you can run
#     `source .venv/bin/activate`
# to activate the virtual environment for your project.
uv sync

# 4. Download human gnomes
# There are 2 formats. Below download the ensembl format only.
# Download Ensembl GRCh38 (approx 800MB compressed)

curl -O http://ftp.ensembl.org/pub/release-110/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
gunzip Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
