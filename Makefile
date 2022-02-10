PHONY=dry_run run

dry_run:
	@echo "-------------------"
	@echo "This is a dryn run!"
	@echo "-------------------"
	@snakemake -pr --dryrun --cores 1 --use-conda --configfile config.yaml

run:
	@snakemake --cores 1 --use-conda --configfile config.yaml
