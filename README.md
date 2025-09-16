# Phylogenetic Applications – Class Repository

This repository contains all datasets, scripts, and example commands used during the **Applications** class on phylogenetic analysis.

## Repository Structure
```

.
├── MKPX/                # Monkeypox sequences, results, and plots
├── HIV/                 # HIV sequences, results, and plots
└── README.md

````

---

## Datasets

### Monkeypox (MKPX)
- **41 sequences**
- **5 subtypes**
- **Average size ≈ 200,000 bp**  
- Sequences sourced from [NCBI Virus](https://www.ncbi.nlm.nih.gov/labs/virus/vssi/#/)

### HIV
- **6,964 sequences** (class examples use a subset of 500)
- **8 subtypes**
- **Average size ≈ 10,000 bp**  
- Sequences sourced from [Los Alamos National Laboratory](https://www.hiv.lanl.gov/content/index)

---

## Getting Started

Clone the repository:
```bash
git clone https://github.com/omatheuspimenta/phylo.git
cd phylo
````

All class files and software instructions are under the `phylo` folder.

---

## Software Installation

Install the required tools:

```bash
# mashtree (via conda)
conda create -n mashtree -c bioconda mashtree

# mike (clone from GitHub)
git clone https://github.com/Argonum-Clever2/mike.git
```

---

## Example Workflows

### 1️⃣ MKPX with **mike**

```bash
# Create absolute paths for sequences
realpath MKPX/seqs/* > seqs_MKPX.txt

# Generate k-mer sketches
while read seq; do
    python kmc.py -k 21 -f "$seq" -d MKPX/output_kmers/
done < seqs_MKPX.txt

# List k-mer files
realpath MKPX/output_kmers/* > kmers_MKPX.txt

# Create mike sketches (single thread)
./mike sketch -t 1 -l kmers_MKPX.txt -d MKPX/output_mike/

# List mike sketches
realpath MKPX/output_mike/* > mike_MKPX.txt

# Compute Jaccard similarity and distances
./mike compute -l mike_MKPX.txt -L mike_MKPX.txt -d MKPX/
./mike dist    -l mike_MKPX.txt -L mike_MKPX.txt -d MKPX/

# Generate a Newick tree
conda activate R4
Rscript draw.r -f MKPX/dist.txt -o MKPX/dist.nwk
```

### 2️⃣ MKPX with **mashtree**

```bash
conda activate mashtree
mashtree MKPX/seqs/*.fasta > MKPX/mashtree.dnd

# Bootstrap (100 reps for class; typically 1000)
mashtree_bootstrap.pl --reps 100 MKPX/seqs/*.fasta -- --min-depth 0 \
  > MKPX/mashtree.bootstrap.dnd
```

### 3️⃣ Plotting MKPX Trees

```bash
conda activate R4
Rscript create_tree_MKPX.R -t MKPX/dist.nwk                -a MKPX/annotation.csv -o MKPX/
Rscript create_tree_MKPX.R -t MKPX/mashtree.dnd            -a MKPX/annotation.csv -o MKPX/
Rscript create_tree_MKPX.R -t MKPX/mashtree.bootstrap.dnd  -a MKPX/annotation.csv -o MKPX/
```

---

### 4️⃣ HIV Challenge with **mashtree**

```bash
conda activate mashtree

# Select 500 sequences
./select_500seqs.sh

# Prepare samples folder
mkdir samples && cat samples.txt | xargs cp -t samples/

# Build phylogenetic trees (11-mers)
mashtree --kmerlength 11 HIV/samples/*.fasta > HIV/mashtree.dnd

# Bootstrap (100 reps for class)
mashtree_bootstrap.pl --reps 100 HIV/samples/*.fasta -- --min-depth 0 --kmerlength 11 \
  > HIV/mashtree.bootstrap.dnd
```

### Plotting HIV Trees

```bash
conda activate R4
Rscript create_tree_HIV.R -t HIV/mashtree.dnd           -a HIV/annotation.csv -o HIV/ --confidence none
Rscript create_tree_HIV.R -t HIV/mashtree.bootstrap.dnd -a HIV/annotation.csv -o HIV/ --confidence color
```

---

## Output Examples

* **MKPX**: mike tree, mashtree tree, and mashtree bootstrap tree.
* **HIV**: mashtree tree and mashtree bootstrap tree.

Use these images for reference or presentations.

---

## License

All files come from the [NCBI](https://www.ncbi.nlm.nih.gov/labs/virus/vssi/#/), [Los Alamos National Laboratory](https://www.hiv.lanl.gov/content/index), [mike](https://github.com/Argonum-Clever2/mike/tree/master), and [mashtree](https://github.com/lskatz/mashtree) repositories.  
Use for educational purposes only.


