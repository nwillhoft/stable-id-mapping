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

include { fromQuery } from 'plugin/nf-sqldb'

workflow {
    
    // count the number of entries to update in the gene table
    channel.fromQuery("SELECT COUNT(*) FROM gene where stable_id LIKE 'gene:%'", db: 'new-db').view{ num -> "Number of stable IDs to update in gene table: $num" }

    // count the number of entries to update in the transcript table
    channel.fromQuery("SELECT COUNT(*) FROM transcript where stable_id LIKE 'transcript:%'", db: 'new-db').view{ num -> "Number of stable IDs to update in transcript table: $num" }

    // count the number of entries to update in the translation table
    channel.fromQuery("SELECT COUNT(*) FROM translation WHERE stable_id LIKE 'CDS:%'", db: 'new-db').view{ num -> "Number of stable IDs to update in translation table: $num" }

}