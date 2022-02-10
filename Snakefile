import os
from os.path import splitext
from functools import partial

data = partial(os.path.join, 'data')
results = partial(os.path.join, config.get('output', 'results'))


def iterate_all_libraries():
  return config['input']['libraries'].keys()


def iterate_all_fastqs(library=None):
  for _library in iterate_all_libraries():
    if library:
      yield config['input']['libraries'][_library]['fastqs']
    else:
      for fastq in config['input']['libraries'][_library]['fastqs']:
        yield fastq


def get_library_fastqs(library):
  return config['input']['libraries'][library]['fastqs']


rule all:
  """Define output file to be generated."""
  input:
    expand(
        results("fastqc", "{fq}_fastqc.zip"),
        fq=[os.path.basename(fastq).replace('.fq.gz', '') for fastq in iterate_all_fastqs()]
    ),
    expand(
        results("vcf", "{library}.vcf"),
        library=iterate_all_libraries()
    )

rule fastq:
  """Use FastQC to check quality of reads."""
  input:
    data("{fq_file}.fq.gz")
  output:
    results("fastqc", "{fq_file}_fastqc.zip")
  conda:
      "envs/fastq.yaml"
  params:
    outdir = results("fastqc")
  shell:
    """fastqc {input} -o {params.outdir}"""

rule generate_bwa_index:
  """Generate BWA index."""
  input:
    ref = config['input']['reference']
  output:
    idx = multiext(config['input']['reference'], ".amb", ".ann", ".bwt", ".pac", ".sa"),
  conda:
      "envs/bwa.yaml"
  shell:
    """
    bwa index {input.ref}
    """

rule map_reads:
  """Align reads to the reference genome."""
  input:
    fqs = lambda wildcards: get_library_fastqs(wildcards.library),
    index = rules.generate_bwa_index.output.idx,
  output:
    bam = results("bwa", "{library}.bam")
  conda:
      "envs/bwa.yaml"
  threads: 1
  params:
    prefix = splitext(rules.generate_bwa_index.output.idx[0])[0]
  shell:
    """
    bwa mem -t {threads} {params.prefix} {input.fqs} | \
        samtools sort -m 2G -@ {threads} -O bam -o {output} -
    """


rule mark_duplicates:
  """Mark duplicates in the aligned reads."""
  input:
    bam = rules.map_reads.output.bam
  output:
    markdup = results("markduplicates", "{library}.md.bam"),
    metrics = results("markduplicates", "{library}.metrics")
  conda:
      "envs/picard.yaml"
  shell:
    """
    picard MarkDuplicates \
        -I {input.bam} \
        -O {output.markdup} \
        -M {output.metrics} \
        -ASSUME_SORTED true
    """

rule prune_reads:
  """Remove duplicates and low quality alignments."""
  input:
    bam = rules.mark_duplicates.output.markdup
  output:
    pruned = results("pruned", "{library}.pruned.bam"),
    pruned_bai = results("pruned", "{library}.pruned.bam.bai")
  conda:
      "envs/bwa.yaml"
  threads:
    config['alignment']['threads']
  params:
    min_mapq = config['alignment']['min_mapq'],
  shell:
    """
    samtools view -b -h -f 3 -F 4 -F 8 -F 256 -F 1024 -F 2048 -q {params.min_mapq} {input.bam} | \
        samtools sort -m 2G -@ {threads} -O bam -o {output.pruned} -

    samtools index {output.pruned}
    """

rule call_variants:
  """Call variants using freebayes."""
  input:
    ref = config['input']['reference'],
    bam = rules.prune_reads.output.pruned
  output:
    vcf = results("vcf", "{library}.vcf")
  conda:
      "envs/variants.yaml"
  shell:
    """
    freebayes -f {input.ref} -b {input.bam} -p 1 > {output}
    """
