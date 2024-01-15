//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_bam_channel(it) }
        .set { reads }

    emit:
    reads                                     // channel: [ val(meta), [ reads ] ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}


// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_bam_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.sample
    meta.state      = row.state
    meta.patient    = row.patient

    // add path(s) of the fastq file(s) to the meta map
    def bam_meta = []
    if (!file(row.bam).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> BAM file does not exist!\n${row.bam}"
    }
    
    if (!file(row.bai).exists()){
        log.warn('Interval files (bai) not provided')
        bam_meta = [ meta, [ file(row.bam) ] ]
    } else {
        bam_meta = [ meta, [ file(row.bam), file(row.bai) ] ]
    }
    return bam_meta
}