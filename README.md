Prompt 1
--------

Variant Calling Pipeline. The pipeline uses Snakemake to map Paired Illumina reads from
a publicly available SARS-CoV-2 dataset ([SRA accession
SRR15660643](https://www.ncbi.nlm.nih.gov/sra/?term=SRR15660643)) downsampled to 16000
paired reads to the Wuhan-Hu-1 reference genome ([Genbank accession
MN908947.3](https://www.ncbi.nlm.nih.gov/nuccore/MN908947.3)).

The pipeline uses `conda` integrated workflow management and requires `snakemake`.

## Usage

To install `snakemake`, run (requires Python 3+):

```
make install
```

Once dependencies are installed, please check `config.yaml` to configure your pipeline.
Sample data is provided with the pipeline and next steps should execute without any
modifications.

To see the list of jobs that will be run, execute:

```
make dry_run
```

Finally, to run the tasks, use:

```
make run
```

## Output

The output files are written to the `output/` directory within the same folder as the
`Snakefile`.
