/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Check mandatory parameters
if (params.input)   { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified! (--input file.csv)' }
if (params.fasta)   { ch_fasta = Channel.fromPath(params.fasta) } else { exit 1, 'Reference fasta file may be required!(--fasta file.fasta)'}
if (params.fai  )   { ch_fai = Channel.fromPath(params.fai)     } else { log.warn('Reference interval fasta not provided. Perfomance may be affected!(--fai file.fai)')}
if (params.sites)   { ch_sites = file(params.sites )} else { log.warn('Sites files is required!')}
if (params.haplomap){ ch_haplomap = file(params.haplomap)} else { log.warn('Haplotype map may be required')}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { SOMALIER_CHECKUP } from '../subworkflows/local/somalier_subworkflow'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//

include { CUSTOM_DUMPSOFTWAREVERSIONS   } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { PICARD_CROSSCHECKFINGERPRINTS } from '../modules/nf-core/picard/crosscheckfingerprints/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow BASICIDENTIFICATION {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    ch_reads = INPUT_CHECK.out.reads
    
    //
    // SUBWORKDLOW: Extract sites and calculate relatedness (SOMALIER)
    //
    if (params.tools && params.tools.split(',').contains('somalier')){
        // execute somalier subworkflow
        ch_in_somalier = ch_reads.map{meta, files ->

        [
            meta,files[0],files[1]
        ]

        }
      
        SOMALIER_CHECKUP(ch_in_somalier, ch_fasta, ch_fai, ch_sites)

    }

    //
    // SUBWORKDLOW: Extract sites and calculate relatedness (SOMALIER)
    //
    if (params.tools && params.tools.split(',').contains('crosscheckfingerprints')){
                
        new_arr = ch_reads.map{meta, files->
            [
                files[0]
            ]
        }.collect()

        new_arr_idx = ch_reads.map{meta, files->
            [
                files[1]
            ]
        }.collect()

        // add meta to channel
        ch_in_finger = new_arr.map{files ->
            meta = [id:'all_samples']
            [
                meta,files
            ]
        }
        // ch_in_finger.view()
        //new_arr_idx.view()

        ch_refs = ch_fasta.concat(ch_fai).collect()

        PICARD_CROSSCHECKFINGERPRINTS(ch_in_finger, [], ch_haplomap, ch_refs)
        //res = PICARD_CROSSCHECKFINGERPRINTS.out.results

    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
