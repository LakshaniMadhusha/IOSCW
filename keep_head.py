import os

def resolve_with_head(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    state = "NORMAL" # NORMAL, IN_HEAD, IN_THEIRS
    changed = False

    for line in lines:
        if line.startswith("<<<<<<< HEAD"):
            state = "IN_HEAD"
            changed = True
        elif line.startswith("======="):
            state = "IN_THEIRS"
        elif line.startswith(">>>>>>>"):
            state = "NORMAL"
        else:
            if state == "NORMAL":
                new_lines.append(line)
            elif state == "IN_HEAD":
                new_lines.append(line)
            elif state == "IN_THEIRS":
                pass

    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f"Resolved in {filepath}")

for root, dirs, files in os.walk('.'):
    for name in files:
        if name.endswith('.swift') or name.endswith('.pbxproj'):
            resolve_with_head(os.path.join(root, name))
