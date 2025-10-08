import sys
import pandas as pd

def parse_blast(file_path, evalue_thresh, identity_thresh):
    hits = []
    with open(file_path) as f:
        for line in f:
            if line.startswith("#") or not line.strip():
                continue
            cols = line.strip().split('\t')
            # Columns based on your example:
            # query acc.ver, subject acc.ver, % identity, alignment length, mismatches,
            # gap opens, q. start, q. end, s. start, s. end, evalue, bit score
            query, subject = cols[0], cols[1]
            pct_identity = float(cols[2])
            evalue = float(cols[10])
            
            if evalue <= evalue_thresh and pct_identity >= identity_thresh:
                hits.append({
                    'query': query,
                    'subject': subject,
                    '% identity': pct_identity,
                    'alignment length': int(cols[3]),
                    'mismatches': int(cols[4]),
                    'gap opens': int(cols[5]),
                    'q start': int(cols[6]),
                    'q end': int(cols[7]),
                    's start': int(cols[8]),
                    's end': int(cols[9]),
                    'evalue': evalue,
                    'bit score': float(cols[11])
                })

    df = pd.DataFrame(hits)
    return df

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python parse_blast_all.py <blast_output.txt> <evalue_thresh> <identity_thresh>")
        sys.exit(1)

    blast_file = sys.argv[1]
    evalue_threshold = float(sys.argv[2])
    identity_threshold = float(sys.argv[3])

    df_hits = parse_blast(blast_file, evalue_threshold, identity_threshold)

    print(f"Found {len(df_hits)} hits passing filters (E-value ≤ {evalue_threshold}, % identity ≥ {identity_threshold})")
    print(df_hits.to_string(index=False))
