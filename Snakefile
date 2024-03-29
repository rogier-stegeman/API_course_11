from pytools.persistent_dict import PersistentDict

storage = PersistentDict("mystorage")

rule all:
    input:
        "report.html"


# Call local API to retrieve variant data based on chromosome (chr), position (pos) and alternative allele (alt)
# rule variant_api:
#     params:
#         chr = os.environ.get("chr"),
#         pos = os.environ.get("pos"),
#         alt = os.environ.get("alt")
#     output:
#         "variant_info.txt"
#     run:
#         shell("wget 'http://0.0.0.0:5000/api?chr={params.chr}&pos={params.pos}&alt={params.alt}' --output-document {output} || true")


# Call ensembl API to retrieve additional information about variant
rule ensembl_api:
    input:
        "variant_info.txt"
    output:
        "ensembl_application.json"
    run:
        try:
            with open(input[0]) as file:
                line = file.readline()
                print(line + " variant\n")
                rsID = str(line.split(",")[2])
                print("Malignant variant\n")
                rsID = rsID.replace("'", "")
	        rsID = rsID.replace(" ", "")
                shell("wget -q --header='Content-type:application/json' 'https://rest.ensembl.org/variation/human/{rsID}?genotyping_chips=1'  --output-document {output} || true")
                storage.store("rsID", rsID)
        except(IndexError):
            print("An error occurred, this is due to a Unknown or Not Malignant variant (see which one above).\nPlease try again with a Malignant variant!\n")
            #shell("rm variant_info.txt")
        except:
            print("An error occurred, unfortunatly this isn't due to a Unknown of Not Malignant variant.\nPlease try again or contact the developer!\n")
            #shell("rm variant_info.txt")


# Call NCBI SNP API to retrieve additional information about variant
rule SNP_api:
    output:
        "SNP_info.json"
    run:
        rsID = storage.fetch("rsID")
        rsShort = rsID.replace("rs", "")
        shell("wget 'https://api.ncbi.nlm.nih.gov/variation/v0/beta/refsnp/{rsShort}' --output-document {output} || true")


# Create workflow
rule workflow:
	output:
		"workflow.svg"
	shell:
		"snakemake --dag all | dot -Tsvg > {output}"


# Create HTML report
rule report:
	input:
		VariantInfo = "variant_info.txt",
        Ensembl = "ensembl_application.json",
        SNP = "SNP_info.json",
	    Workflow = "workflow.svg"
	output:
		"report.html"
	run:
		from snakemake.utils import report
		report("""API Course 11 version 1.0 (proof of concept)""", output[0], metadata="Authors: Awan & Melanie", **input)


onsuccess:
    print("\nWorkflow finished without errors!")

onerror:
    print("\nSnakemake stopped!")
