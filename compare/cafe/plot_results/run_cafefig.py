from xvfbwrapper import Xvfb
import subprocess

with Xvfb() as xvfb:
    subprocess.run([
        "python3",
        "/hpc/group/bio1/ewhisnant/comp-genomics/scripts/compare/cafe/cafefig.py",
        "--dump", "/hpc/group/bio1/ewhisnant/comp-genomics/compare/cafe/lecanoromycetes/v25.06.18/90filtered/cafefig",
        "--gfx_output_format", "pdf",
        "-pb","0.05",
        "-pf","0.05",
        "--count_all_expansions",
        "/hpc/group/bio1/ewhisnant/comp-genomics/compare/cafe/lecanoromycetes/v25.06.18/95filtered/HOGs_fasttree/Gamma_report.cafe"
    ])

    