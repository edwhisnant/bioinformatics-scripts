# === Script reads the Gamma_results.txt file from CAFE and parse the results in a human readable format
# ===  CLI usage:
# 		python3 extract_cafe_gamma_results.py \
#			${INPUT_DIR}/Gamma_results.txt \
#			${INPUT_DIR}/output.tsv

import re
import sys

input_file = sys.argv[1]
output_file = sys.argv[2]

with open(input_file) as f:
    text = f.read()

# Extract values
likelihood = re.search(r"Model Gamma Final Likelihood \(-lnL\):\s*([^\n]+)", text)
lambda_ = re.search(r"Lambda:\s*([^\n]+)", text)
alpha = re.search(r"Alpha:\s*([^\n]+)", text)

# Count families with failure rates >20%
failures_section = re.search(r"The following families had failure rates >20% of the time:(.*?)(Alpha:|$)", text, re.DOTALL)
if failures_section:
    failures = [line for line in failures_section.group(1).splitlines() if line.strip() and "had" in line]
    num_failures = len(failures)
else:
    num_failures = 0

# Write to TSV
with open(output_file, "w") as out:
    out.write("Likelihood\tLambda\tAlpha\tNumFamiliesFailure20pct\n")
    out.write(f"{likelihood.group(1).strip() if likelihood else ''}\t"
              f"{lambda_.group(1).strip() if lambda_ else ''}\t"
              f"{alpha.group(1).strip() if alpha else ''}\t"
              f"{num_failures}\n")

print(f"Extracted values saved to {output_file}")
