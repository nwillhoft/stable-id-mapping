#!/usr/bin/env python

import typer
import os
from Bio import SeqIO
from typing import Optional
from typing_extensions import Annotated

app = typer.Typer()

@app.command()
def chunk_fasta(fasta_file: Annotated[str, typer.Argument(help="The path of the FASTA file to break into chunks")],
                output_dir: Annotated[str, typer.Argument(help="The path of the output directory")]):
    
    with open(fasta_file) as handle:
        for record in SeqIO.parse(handle, "fasta"):
            output_file = output_dir + "/" + record.id + ".fa"
            print(output_file)
            with open(output_file, "w") as out_handle:
                # print(">",record.description)
                SeqIO.write(record, out_handle, "fasta")
    handle.close()


@app.command()
def chunk_gff3(gff3_file: Annotated[str, typer.Argument(help="The path of the GFF3 file to break into chunks")],
               output_dir: Annotated[str, typer.Argument(help="The path of the output directory")]):

    print("Will break up GFF3 file into chunks...")

    in_handle = open(gff3_file, "r")

    for line in in_handle:
        # print(line)
        if (line.startswith('#')):
            pass
        else:
            all_words = line.split()
            seq_region = all_words[0]
            out_file = output_dir + "/" + seq_region + ".gff3"
            out_handle = open(out_file, "a")
            out_handle.write(line)
            # print(seq_region)

    print("Finished.")


@app.command()
def chunk_mapping_file(mapping_file: Annotated[str, typer.Argument(help="The path of the mapping file to break into chunks")], 
                       output_dir: Annotated[str, typer.Argument(help="The path of the output directory")]):

    mapping_dict = parse_mapping_file(mapping_file)

    # define the path for a mapping_files directory
    mapping_dir = "mapping_files"
    path = os.path.join(output_dir, mapping_dir)
    print("Checking to see if path exists:", path)

    # try to create this directory
    if not os.path.exists(path):
        os.makedirs(path)
        print("Directory '%s' created successfully" % path)
    else:
        print("Directory '%s' already exists" % path)

    for id1 in mapping_dict:
        id2 = mapping_dict[id1]

        mapping_file = path + "/" + id1 + ".mapping"
        mapping_h = open(mapping_file, "w")

        mapping_h.write(id1 + "," + id2)
        mapping_h.close()


def parse_mapping_file(mapping_file):
    mapping_handle = open(mapping_file, "r")

    mapping_dict = {}
    for line in mapping_handle:
        # chomp newline character
        line = line.rstrip('\n')
        # print(line)

        # split line into ref vs target ids
        words = line.split(',')
        # print("words: ", words[0], words[1])
        mapping_dict[words[0]] = words[1]
    
    print("Mapping dictionary:", mapping_dict)
    return mapping_dict


@app.command()
def build_liftoff_command(work_dir: Annotated[str, typer.Argument(help="The name of the work directory to store results in")],
                          ref_fasta: Annotated[str, typer.Argument(help="The path of the reference FASTA file")],
                          target_fasta: Annotated[str, typer.Argument(help="The path of the target FASTA file")], 
                          ref_gff3: Annotated[str, typer.Argument(help="The path of the reference GFF3 file")], 
                          mapping_file: Annotated[Optional[str], typer.Argument(help="The file path of the chromosome mapping(s)")] = None):

    # break down ref fasta to get hold of ref id
    ref_filename = os.path.basename(ref_fasta)
    ref_id, ref_ext = os.path.splitext(ref_filename)

    # break down target fasta to get hold of target id
    target_filename = os.path.basename(target_fasta)
    target_id, target_ext = os.path.splitext(target_filename)

    # create file path to store liftoff results
    output_file = (f"{work_dir}/{ref_id}_{target_id}.mapping.gff3")

    # create file path to store unmapped features
    unmapped_file = (f"{work_dir}/{ref_id}.unmapped")
    
    # construct command to run
    command = None
    if mapping_file is None:
        command = (f"liftoff -g {ref_gff3} -o {output_file} -u {unmapped_file} {target_fasta} {ref_fasta}")
    else:
        command = (f"liftoff -g {ref_gff3} -o {output_file} -chroms {mapping_file} -u {unmapped_file} {target_fasta} {ref_fasta}")
    print(command)
    return command, ref_id

@app.command()
def build_liftoff_bsub(work_dir: Annotated[str, typer.Argument(help="The name of the work directory to store results in")],
                        ref_fasta: Annotated[str, typer.Argument(help="The path of the reference FASTA file")],
                        target_fasta: Annotated[str, typer.Argument(help="The path of the target FASTA file")], 
                        ref_gff3: Annotated[str, typer.Argument(help="The path of the reference GFF3 file")], 
                        mapping_file: Annotated[Optional[str], typer.Argument(help="The file path of the chromosome mapping(s)")] = None):
    
    print("Building liftoff bsub command...")

    # get liftoff command to run
    if mapping_file is None:
        command, ref_id = build_liftoff_command(work_dir, ref_fasta, target_fasta, ref_gff3)
    else:
        command, ref_id = build_liftoff_command(work_dir, ref_fasta, target_fasta, ref_gff3, mapping_file)

    # build up bsub command
    farm_script_path = "run-liftoff." + ref_id + ".sh"
    out_h = open(farm_script_path, "w")

    L = ["#!/usr/bin/env bash\n", "#BSUB -J liftoff\n", "#BSUB -W 5:00\n", "#BSUB -n 1\n", "#BSUB -q standard\n", "#BSUB -e error.%J\n", "#BSUB -o output.%J\n"]
    out_h.writelines(L)

    out_h.write("WORKDIR=" + work_dir + "\n")
    out_h.write("cd $WORKDIR\n")

    out_h.write(command)

    out_h.close()
    print("Written out lines to:", farm_script_path)


@app.command()
def build_synteny_command(ref_fasta: str, 
         target_fasta: str,
         ref_gff3: str,
         target_gff3: str,
         output_dir: str):
    print("Building synteny command...")

    # example command:
    # liftofftools -r /nfs/production/flicek/ensembl/infrastructure/nwillhoft/id_mapping/northern_pike/run_per_chromosome/reference_fasta/LG01.fa -t /nfs/production/flicek/ensembl/infrastructure/nwillhoft/id_mapping/northern_pike/run_per_chromosome/target_fasta/1.fa -rg /nfs/production/flicek/ensembl/infrastructure/nwillhoft/id_mapping/northern_pike/run_per_chromosome/reference_gff3/LG01.gff3 -tg ../LG01_1.mapping.gff3 -edit-distance -force synteny

    command = (f"liftofftools -r {ref_fasta} -t {target_fasta} -rg {ref_gff3} -tg {target_gff3} -dir {output_dir} -edit-distance -force synteny\n")
    return command


@app.command()
def build_synteny_bsub(ref_fasta: str, 
         target_fasta: str,
         ref_gff3: str,
         target_gff3: str,
         output_dir: str):
    print("Building bsub synteny command...")

    filename = os.path.basename(ref_fasta)
    ref_id, ext = os.path.splitext(filename)
    print("ref_id:", ref_id)

    command = build_synteny_command(ref_fasta, target_fasta, ref_gff3, target_gff3, output_dir + "/" + ref_id)

    # build up bsub command
    farm_script_path = "run-synteny." + ref_id + ".sh"
    out_h = open(farm_script_path, "w")

    L = ["#!/usr/bin/env bash\n", "#BSUB -J synteny\n", "#BSUB -W 5:00\n", "#BSUB -n 1\n", "#BSUB -q standard\n", "#BSUB -e error.%J\n", "#BSUB -o output.%J\n", "\nsource /hps/software/users/ensembl/ensw/swenv/spack/share/spack/setup-env.sh\n", "spacktivate experimental-liftoff\n"]
    out_h.writelines(L)

    # out_h.write("WORKDIR=" + work_dir + "\n")
    # out_h.write("cd $WORKDIR\n")

    out_h.write(command)

    out_h.close()
    print("Written out lines to:", farm_script_path)

    # print(command)


if __name__ == "__main__":
    # typer.run(main)
    app()