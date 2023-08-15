/*
 * pipeline input parameters
 */

include { fromQuery } from 'plugin/nf-sqldb'

params.current_db_name = "triticum_aestivum_core_57_110_4"
params.current_db_host = "mysql-ens-mirror-3" 
params.current_db_port = "4275"
params.current_db_user = "ensro"
params.new_db_name = "nwillhoft_triticum_aestivum_core_57_110_4"
params.new_db_host = "mysql-ens-core-prod-1" 
params.new_db_port = "4524"
params.new_db_user = "ensadmin"
params.new_db_pwd  = ""
params.liftoff_gff3_file = ""

log.info """\

    S T A B L E   I D   M A P P I N G   (P T 2)   -   N F   P I P E L I N E
    =======================================================================

    current database name    : ${params.current_db_name}
    current database host    : ${params.current_db_host}
    current database port    : ${params.current_db_port}
    current database user    : ${params.current_db_user}

    new database name        : ${params.new_db_name}
    new database host        : ${params.new_db_host}
    new database port        : ${params.new_db_port}
    new database user        : ${params.new_db_user}

    liftoff GFF3 results file: ${params.liftoff_gff3_file}

    """
    .stripIndent(true)

process COUNT_MAPPED_GENES {


    // -e "SELECT count(*) FROM GENE WHERE source = 'Liftoff';"
    """
    ${params.new_db_host} ${params.new_db_name} -e "SELECT biotype, COUNT(biotype) 
    FROM gene 
    WHERE source = 'Liftoff'
    GROUP BY biotype;"
    """
}

process COUNT_GFF3_FEATS {

    """
    awk '{if (\$1 !~ /^#/) print \$3}' ${params.liftoff_gff3_file} | sort | uniq -c
    """
}

process REMOVE_GENE_PREFIX {

    """
    ${params.new_db_host} ${params.new_db_name} -e "SELECT COUNT(*)
    FROM gene
    WHERE stable_id LIKE 'gene:%'"
    """

}

process REMOVE_TRANSCRIPT_PREFIX {

    """
    ${params.new_db_host} ${params.new_db_name} -e "SELECT COUNT(*)
    FROM transcript
    WHERE stable_id LIKE 'transcript:%'"
    """

}

process REMOVE_TRANSLATION_PREFIX {

    """
    ${params.new_db_host} ${params.new_db_name} -N -e "SELECT COUNT(stable_id)
    FROM translation
    WHERE stable_id LIKE 'CDS:%'"
    """

}

/*
This workflow will:
 - generate stats on how many IDS were loaded into the new db
 - update data in db to remove prefixes added during load pipeline
 - update data in db to inherit certain attributes from current db
*/

workflow {
    
    channel.fromQuery("SELECT COUNT(stable_id) FROM translation WHERE stable_id LIKE 'CDS:%'", db: 'new-db').view{ num -> "Number of stable IDs to update in translation table: $num" }

}

// WHERE stable_id LIKE 'CDS:%'