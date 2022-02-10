desc "Dry run pipeline"
task :dry_run do |t|
  puts 'This is a dry run'
  puts '-----------------'
  # sh "snakemake -pr --dryrun --cores 1 --use-singularity --configfile config.yaml "
  sh "snakemake -pr --dryrun --cores 1 --use-conda --configfile config.yaml "
end

desc "Run pipeline"
task :run do |t|
  # sh "snakemake --cores 1 --use-singularity --configfile config.yaml"
  sh "snakemake --cores 1 --use-conda --configfile config.yaml "
end
