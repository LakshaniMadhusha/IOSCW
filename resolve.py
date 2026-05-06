import os
import glob

def print_conflicts(directory):
    files = []
    for root, dirs, filenames in os.walk(directory):
        for filename in filenames:
            if filename.endswith(".swift") or filename.endswith(".pbxproj"):
                path = os.path.join(root, filename)
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        content = f.read()
                        if "<<<<<<< HEAD" in content:
                            files.append(path)
                except Exception:
                    pass
    
    for path in sorted(files):
        print(f"\n--- {path} ---")
        with open(path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        
        in_conflict = False
        conflict_lines = []
        for line in lines:
            if line.startswith("<<<<<<< HEAD"):
                in_conflict = True
                conflict_lines.append(line)
            elif line.startswith(">>>>>>>"):
                conflict_lines.append(line)
                in_conflict = False
                print("".join(conflict_lines))
                conflict_lines = []
            elif in_conflict:
                conflict_lines.append(line)

print_conflicts("/Users/cobsccomp242p-062/Documents/SmartLibrary-main-2")
