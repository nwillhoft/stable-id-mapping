// See the NOTICE file distributed with this work for additional information
// regarding copyright ownership.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

nextflow.enable.dsl=2

process RUN_MAPPING {
    // executor = 'slurm'
    executor = 'lsf'
    queue = 'standard'
    clusterOptions = '-W 72:00'

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