#from cx_Freeze import setup, Executable

base = None    

executables = [Executable("c4dev.py", base=base)]

#packages = ["idna",'platform', 'shutil','copy', 'pickle', 'os', 'tty', 'tarfile']
options = {
    'build_exe': { 
        'build_exe': 'build/c4dev',   
        'packages':packages,
    },    
}

setup(
    name = "c4dev",
    options = options,
    version = "0.1",
    description = 'Strumento di supporto allo sviluppo Control4',
    executables = executables
)

