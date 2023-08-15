/*
 * pipeline input parameters
 */
params.ref_fasta       = "$PWD/reference_fasta/Bacteroides_uniformis_atcc_8492_gca_000154205.ASM15420v1.dna_rm.toplevel.fa"
params.ref_gff3        = "$PWD/reference_gff3/Bacteroides_uniformis_atcc_8492_gca_000154205.ASM15420v1.49.gff3"
params.target_fasta    = "$PWD/target_fasta/b_uniformis_atcc8492_bc2018.fna"
params.outdir          = "mapping_results"
params.results_file    = "${params.species}.mapping.gff3"
params.exclude_partial = "True"
params.polish          = "True"
params.chr_mapping     = ""
params.lotools_mode    = "all"
params.species         = "b_uniformis"

log.info """\
    S T A B L E   I D   M A P P I N G  -  N F   P I P E L I N E
    ===========================================================

    reference FASTA file    : ${params.ref_fasta}
    reference GFF3 file     : ${params.ref_gff3}
    target FASTA file       : ${params.target_fasta}
    liftoff results file    : ${params.results_file}
    exclude partial mappings: ${params.exclude_partial}
    polish option           : ${params.polish}
    chromosome mapping file : ${params.chr_mapping}
    """
    .stripIndent(true)


process RUN_MAPPING {
    // executor = 'slurm'
    executor = 'lsf'
    queue = 'standard'
    clusterOptions = '-W 72:00'

    // set up spack environment: https://www.nextflow.io/docs/latest/spack.html#spack-page
    // tried this beforeScript command but seems to cause an error
    // beforeScript 'source /hps/software/users/ensembl/ensw/swenv/initenv default'
    // module load nextflow-22.10.1-gcc-11.2.0-ju5saqw

    // capture mapping-related files into relevant output dir
    publishDir "$params.species/$params.outdir/", pattern: "*.gff3*"
    publishDir "$params.species/$params.outdir/", pattern: "*.gff3_polished"

    input:
    path ref_fasta
    path ref_gff3
    path target_fasta

    output:
    path params.results_file

    script:
    // this seems a nice, easily-readable way to add in optional parameters
    def filter_partial = params.exclude_partial ? "-exclude_partial" : ''
    def apply_polish = params.polish ? "-polish" : ''
    def use_chr_mapping = params.chr_mapping != "" ? "-chroms ${params.chr_mapping}" : ''

    """
    liftoff -g $ref_gff3 \
    -o $params.results_file \
    $use_chr_mapping \
    $filter_partial \
    $apply_polish \
    $target_fasta \
    $ref_fasta
    """
}

process RUN_LIFTOFFTOOLS {
    // executor = 'slurm'
    executor = 'lsf'
    queue = 'standard'
    clusterOptions = '-W 72:00'

    input:
    path ref_fasta
    path target_fasta
    path ref_gff3
    path target_gff3
    val mode

    script:
    """
    liftofftools -r $ref_fasta -t $target_fasta -rg $ref_gff3 -tg $target_gff3 $mode
    """
}

// https://www.ebi.ac.uk/seqdb/confluence/display/EnsGen/Load+GFF3+Pipeline#LoadGFF3Pipeline-Loadintoanotherfeaturesdatabase
// can see mention of 'gt gff3 -tidy' option and 'gt gff3validator', and I know strand needed fixing when looking at b.uniformis
// add these two steps in (can I run at same time?)

// process POST_PROCESSING {

    // Remove entries with valid_ORFs=0 ?
    // tidy file with 'gt gff3 -tidy'?
    // validate file with 'gt gff3validator'?
    // https://github.com/Ensembl/ensembl-genomio/blob/main/pipelines/nextflow/modules/gff3/process_gff3.nf
    // https://github.com/Ensembl/ensembl-genomio/blob/main/pipelines/nextflow/modules/gff3/gff3_validation.nf

// }

process UPLOAD_RESULTS {

    // Use currently available GFF3 load pipeline
    params.ens_version = "110"
    params.mz_release  = "57"

    // export ENS_VERSION=110
    // export MZ_RELEASE=57
    // ./ensembl-production-metazoa/scripts/mz_generic.sh env_setup_only 2>&1 | tee env_setup_110.log

    // cd /nfs/production/flicek/ensembl/infrastructure/nwillhoft/id_mapping/lib

    // source ensembl.prod.110/setup.sh
    // module load libffi-3.3-gcc-9.3.0-cgokng6

    OUT_DIR=outdir
    CMD=co1-w
    PROD_SERVER=meta1
    PROD_DBNAME=ensembl_production
    SPECIES=triticum_aestivum
    LOGIC_NAME=gff3_import_raw
    GENE_SOURCE=liftoff

    GFF3_FILE=/nfs/production/flicek/ensembl/infrastructure/nwillhoft/id_mapping/triticum_aestivum/Triticum_aestivum.TGACv1.dna.toplevel_Triticum_aestivum.IWGSC.dna.toplevel.mapping.gff3_polished

    """
    echo "Printing out commands to initialise hive pipeline..."
    echo "source /hps/software/users/ensembl/ensw/latest/envs/essential.sh"
    echo "export ENS_VERSION=${params.ens_version}"
    echo "export MZ_RELEASE-${params.mz_version}"
    echo "./ensembl-production-metazoa/scripts/mz_generic.sh env_setup_only 2>&1 | tee env_setup_${params.ens_version}.log"
    echo "cd /nfs/production/flicek/ensembl/infrastructure/nwillhoft/id_mapping/lib"
    echo "source ensembl.prod.${params.ens_version}/setup.sh"
    echo "module load libffi-3.3-gcc-9.3.0-cgokng6"
    """

}

// process GENERATE_STATS {

    // print out counts for each type of mapped feature
    // print out counts for unmapped features

// }

workflow {
    results_file = RUN_MAPPING( params.ref_fasta, params.ref_gff3, params.target_fasta )

    // if the -polish arg was used in RUN_MAPPING, the results_file needs "_polished" appended before feeding in below
    // def appended_results_filename = params.polish ? "${params.results_file}_polished" : results_file
    // if (params.polish)


    // RUN_LIFTOFFTOOLS( params.ref_fasta, params.target_fasta, params.ref_gff3, results_file, params.lotools_mode )
}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone!\n" : "Oops .. something went wrong" )
}