include { SOMALIER_EXTRACT  } from '../../modules/nf-core/somalier/extract/main'
include { SOMALIER_RELATE   } from '../../modules/nf-core/somalier/relate/main'
include { SOMALIER_REPORT   } from '../../modules/local/somalier/generate_reports'

workflow SOMALIER_CHECKUP{
    take:
        ch_reads          // channel with cram and crai markduplicates [meta, cram, crai]
        ch_fasta            // channel with reference fasta
        ch_fasta_fai        // channel with reference fasta intervals
        ch_sites            // channel with sites map
        //ch_ped              // channel with ped file                      [optional]
    main:
        // create empty channel to gather versions
        ch_versions = Channel.empty()

        // execute somalier extract
        SOMALIER_EXTRACT(ch_reads, ch_fasta, ch_fasta_fai, ch_sites)
        
        //output channels
        ch_soma_extract = SOMALIER_EXTRACT.out.extract
        ch_versions = ch_versions.mix(SOMALIER_EXTRACT.out.versions)

        // reformat channel, Get files into list
        ch_final = ch_soma_extract.map{meta, files ->
            [
                files
            ]
        }.collect()

        // add meta and ped (empty) file
        
        ch_final.map{files->
            meta = [id:'all_samples']
            [
                meta, files, []
            ]
        }.set{ch_input}
        
        // Execute somalier relate
        SOMALIER_RELATE(ch_input,[])
        
        // gather outputs
        ch_versions = ch_versions.mix(SOMALIER_RELATE.out.versions)
        ch_reports = SOMALIER_RELATE.out.pairs_tsv

        // SOMALIER_CHECKUP(ch_reports)
    emit:
        ch_versions
}