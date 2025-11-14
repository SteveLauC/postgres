#!/usr/bin/python3

import os
import subprocess
import sys

# Configuration variables
POSTMASTER_PORT = "5433"
MESON_BUILD_DIR = "meson_build_dir"
INSTALL_DIR = "install_dir"
DATA_DIR = "data_dir"
DATABASE = "postgres"

def run_command(command, check_success=True, cwd=None):
    print(f"Executing: {' '.join(command)}")
    try:
        result = subprocess.run(command, check=check_success, cwd=cwd)
        return result
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(f"Command not found: {command[0]}. Make sure it's in your PATH.", file=sys.stderr)
        sys.exit(1)

def setup():
    current_pwd = os.getcwd()

    cmd_args = ["meson", "setup", MESON_BUILD_DIR]
    if sys.platform == 'darwin':
        # Assuming system_tzdata path is known for macOS with Homebrew PostgreSQL
        system_tzdata_path = "/opt/homebrew/opt/postgresql@17/share/postgresql/timezone"
        cmd_args.append( f"-Dsystem_tzdata={system_tzdata_path}",)
    cmd_args.append(f"--prefix={current_pwd}/{INSTALL_DIR}")
    cmd_args.append("--debug")

    run_command(cmd_args)
   

def compile_project():
    run_command(["meson", "compile", "-C", MESON_BUILD_DIR])

def install_project():
    run_command(["meson", "install", "-C", MESON_BUILD_DIR])
    install_path = os.path.join(os.getcwd(), INSTALL_DIR)
    os.system(f"cd {install_path} && echo '*' > .gitignore")

def initdb():
    initdb_path = os.path.join(os.getcwd(), INSTALL_DIR, "bin", "initdb")
    run_command([initdb_path, "-D", DATA_DIR])
    data_path = os.path.join(os.getcwd(), DATA_DIR)
    os.system(f"cd {data_path} && echo '*' > .gitignore;")

def start_master():
    pg_ctl_path = os.path.join(os.getcwd(), INSTALL_DIR, "bin", "pg_ctl")
    run_command([pg_ctl_path, "-D", DATA_DIR, "-o", f"-p {POSTMASTER_PORT}", "start"])

def stop_master():
    pg_ctl_path = os.path.join(os.getcwd(), INSTALL_DIR, "bin", "pg_ctl")
    run_command([pg_ctl_path, "-D", DATA_DIR, "-o", f"-p {POSTMASTER_PORT}", "stop"])

def single_user_mode():
    postgres_path = os.path.join(os.getcwd(), INSTALL_DIR, "bin", "postgres")
    run_command([postgres_path, "--single", "-D", DATA_DIR, DATABASE])

def connect_psql():
    psql_path = os.path.join(os.getcwd(), INSTALL_DIR, "bin", "psql")
    run_command([psql_path, "--port", POSTMASTER_PORT, DATABASE])

def psql_session():
    start_master()
    connect_psql()
    stop_master()

def show_help():
    print("Available commands:")
    print("  setup         - Configure the build environment.")
    print("  compile       - Compile the project.")
    print("  install       - Install the compiled project.")
    print("  initdb        - Initialize the PostgreSQL database cluster.")
    print("  start-master  - Start the PostgreSQL master server.")
    print("  stop-master   - Stop the PostgreSQL master server.")
    print("  single        - Start PostgreSQL in single-user mode.")
    print("  conn          - Connect to the PostgreSQL database using psql.")
    print("  psql          - Start master, connect with psql, then stop master.")
    print("  help          - Show this help message.")

def main():
    if len(sys.argv) < 2:
        show_help()
        sys.exit(1)

    command = sys.argv[1]
    if command == "setup":
        setup()
    elif command == "compile":
        compile_project()
    elif command == "install":
        install_project()
    elif command == "initdb":
        initdb()
    elif command == "start-master":
        start_master()
    elif command == "stop-master":
        stop_master()
    elif command == "single":
        single_user_mode()
    elif command == "conn":
        connect_psql()
    elif command == "psql":
        psql_session()
    elif command == "help" or command == "--help" or command == "-h":
        show_help()
    else:
        print(f"Unknown command: {command}", file=sys.stderr)
        show_help()
        sys.exit(1)

if __name__ == "__main__":
    main()