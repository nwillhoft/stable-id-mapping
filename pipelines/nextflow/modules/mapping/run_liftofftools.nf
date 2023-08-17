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