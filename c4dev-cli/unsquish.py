import re
import argparse
import os

def save_lua_file(pack_id, content,out_folder):
    identifiers = pack_id.split('.')
    file_name = f"{identifiers[-1]}.lua"
    folders = identifiers[:-1]

    print(f"{pack_id}: {file_name} => {folders}")
    
    new_folder = os.path.abspath(os.path.join(out_folder,*folders))
    print(new_folder)
    if (not os.path.isdir(new_folder)):
        os.makedirs(new_folder)

    new_file = os.path.join(new_folder, file_name)
    with open(new_file,"w") as f:
        f.write(content)


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("luafile")
    parser.add_argument("-o", "--output-folder", default="./unsquized")
    
    args = parser.parse_args()
    print(args)
    
    squished_lua = ""
    with open(args.luafile) as f:
        squished_lua=f.read()
    
    regex = r"package\.preload\['([^']+)'\] = \(function \(\.\.\.\)([\s\S]+?)end\)"

    matches = re.finditer(regex, squished_lua)

    for matchNum, match in enumerate(matches, start=1):
        pack_id, file_content = match.groups()
        #print (f"{pack_id}: {len(file_content)}")

        save_lua_file(pack_id, file_content, args.output_folder)