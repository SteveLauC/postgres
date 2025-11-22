#!/usr/bin/env python3

import os
import subprocess
import sys
from typing import List, Union

def sh(command: Union[str, List[str]]):
    if isinstance(command, str):
        os.system(command)
    elif isinstance(command, List):
        subprocess.run(command)
    else:
        raise TypeError("command should be either a string or an array of string")


# Configuration variables
POSTMASTER_PORT = "5433"
MESON_BUILD_DIR = "meson_build_dir"
INSTALL_DIR = "install_dir"
DATA_DIR = "data_dir"
DATABASE = "postgres"


def setup():
    current_pwd = os.getcwd()

    cmd_args = ["meson", "setup", MESON_BUILD_DIR]
    if sys.platform == 'darwin':
        # Assuming system_tzdata path is known for macOS with Homebrew PostgreSQL
        system_tzdata_path = "/opt/homebrew/opt/postgresql@17/share/postgresql/timezone"
        cmd_args.append( f"-Dsystem_tzdata={system_tzdata_path}",)
    cmd_args.append(f"--prefix={current_pwd}/{INSTALL_DIR}")
    cmd_args.append("--debug")

    sh(cmd_args)
    os.system("")

def compile_project():
    sh(["meson", "compile", "-C", MESON_BUILD_DIR])

def install_project():
    sh(["meson", "install", "-C", MESON_BUILD_DIR])
    install_path = os.path.join(os.getcwd(), INSTALL_DIR)
    os.system(f"cd {install_path} && echo '*' > .gitignore")

def initdb():
    initdb_path = os.path.join(os.getcwd(), INSTALL_DIR, "bin", "initdb")
    sh([initdb_path, "-D", DATA_DIR])
    data_path = os.path.join(os.getcwd(), DATA_DIR)
    sh(f"cd {data_path} && echo '*' > .gitignore;")
    
def re_initdb():
    sh("rm -r data_dir")
    initdb()

def start_master():
    pg_ctl_path = os.path.join(os.getcwd(), INSTALL_DIR, "bin", "pg_ctl")
    sh([pg_ctl_path, "-D", DATA_DIR, "-o", f"-p {POSTMASTER_PORT}", "start"])

def stop_master():
    pg_ctl_path = os.path.join(os.getcwd(), INSTALL_DIR, "bin", "pg_ctl")
    sh([pg_ctl_path, "-D", DATA_DIR, "-o", f"-p {POSTMASTER_PORT}", "stop"])

def single_user_mode():
    postgres_path = os.path.join(os.getcwd(), INSTALL_DIR, "bin", "postgres")
    sh([postgres_path, "--single", "-D", DATA_DIR, DATABASE])

def connect_psql():
    psql_path = os.path.join(os.getcwd(), INSTALL_DIR, "bin", "psql")
    sh([psql_path, "--port", POSTMASTER_PORT, DATABASE])

def psql_session():
    start_master()
    connect_psql()
    stop_master()

def run_project():
    compile_project() 
    install_project() 
    psql_session() 

def show_help():
    print("Available commands:")
    print("  setup         - Configure the build environment.")
    print("  compile(c)    - Compile the project.")
    print("  install(i)    - Compile the project if needed, then install the compiled project.")
    print("  initdb        - Initialize the PostgreSQL database cluster.")
    print("  re-initdb     - Re-initialize the PostgreSQL database cluster.")
    print("  start-master  - Start the PostgreSQL master server.")
    print("  stop-master   - Stop the PostgreSQL master server.")
    print("  single        - Start PostgreSQL in single-user mode.")
    print("  conn          - Connect to the PostgreSQL database using psql.")
    print("  psql(p)       - Start master, connect with psql, then stop master.")
    print("  run(r)        - Compile, install, then run it")
    print("  help          - Show this help message.")

def main():
    if len(sys.argv) < 2:
        show_help()
        sys.exit(1)

    command = sys.argv[1]
    if command == "setup":
        setup()
    elif command == "compile" or command == "c":
        compile_project()
    elif command == "install" or command == "i":
        install_project()
    elif command == "initdb":
        initdb()
    elif command == "re-initdb":
        re_initdb()
    elif command == "start-master":
        start_master()
    elif command == "stop-master":
        stop_master()
    elif command == "single":
        single_user_mode()
    elif command == "conn":
        connect_psql()
    elif command == "psql" or command == "p":
        psql_session()
    elif command == "run" or command == "r":
        run_project()
    elif command == "help" or command == "--help" or command == "-h":
        show_help()
    else:
        print(f"Unknown command: {command}", file=sys.stderr)
        show_help()
        sys.exit(1)

if __name__ == "__main__":
    main()