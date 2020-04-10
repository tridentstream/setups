import random
import subprocess
import string

from pathlib import Path

PWD = Path(__file__).parent.absolute()
ENVIRON = PWD / Path(".environ")
POSTGRES_DATA_PATH = PWD / Path("pg-data")
REQUIREMENTS = PWD / Path("requirements.txt")
PACKAGE_PATH = PWD / Path("packages")

def random_string(stringLength=10):
    letters = string.digits + string.ascii_letters
    return ''.join(random.choice(letters) for i in range(stringLength))


def read_environ():
    environ = {}
    with ENVIRON.open() as f:
        for l in f:
            k, v = l.split("=", 1)
            environ[k] = v.strip("\n")
    return environ


def start_postgres():
    try:
        subprocess.check_call(["pgsql/bin/pg_ctl.exe", "-D", str(POSTGRES_DATA_PATH), "status"])
    except subprocess.CalledProcessError as err:
        if err.returncode == 3:
            subprocess.check_call(["pgsql/bin/pg_ctl.exe", "-D", str(POSTGRES_DATA_PATH), "-l", "logfile", "start"])

def create_postgres_database():
    if not POSTGRES_DATA_PATH.exists():
        subprocess.check_call(["pgsql/bin/initdb.exe", "-U", "postgres", str(POSTGRES_DATA_PATH)])
        start_postgres()
        subprocess.check_call(["pgsql/bin/createuser.exe", "-U", "postgres", "tridentstream"])
        subprocess.check_call(["pgsql/bin/createdb.exe", "-U", "postgres", "tridentstream"])


def install_requirements():
    if not REQUIREMENTS.exists():
        REQUIREMENTS.touch()
    
    subprocess.check_call(["Python/python.exe", "-m", "pip", "install", "-r", str(REQUIREMENTS)])


def install_packages():
    if not PACKAGE_PATH.exists():
        PACKAGE_PATH.mkdir()
    
    for package in PACKAGE_PATH.iterdir():
        if package.name.endswith(".tar.gz") or package.name.endswith(".zip") or package.name.endswith(".whl"):
            subprocess.check_call(["Python/python.exe", "-m", "pip", "install", str(package)])


def bootstrap_tridentstream():
    subprocess.check_call(["Python/python.exe", "Python/Scripts/bootstrap-tridentstream"])


def start_tridentstream():
    environ = read_environ()
    if environ['PRIVATE_KEY']:
        conn_str = f"ssl:{environ['PORT']}:interface={environ['HOST']}:privateKey={environ['PRIVATE_KEY']}:certKey={environ['CERT_KEY']}"
    else:
        conn_str = f"tcp:{environ['PORT']}:interface={environ['HOST']}"
    
    subprocess.check_call(["Python/python.exe", "-m", "twisted", "tridentstream", "-e", conn_str])


def create_environ():
    if not ENVIRON.exists():
        with ENVIRON.open("w") as f:
            f.write(f"SECRET_KEY={random_string(24)}\n")

            MEDIA_ROOT = PWD / "media"
            MEDIA_ROOT.mkdir(parents=True, exist_ok=True)
            f.write(f"MEDIA_ROOT={MEDIA_ROOT}\n")

            DATABASE_ROOT = PWD / "dbs"
            DATABASE_ROOT.mkdir(parents=True, exist_ok=True)
            f.write(f"DATABASE_ROOT={DATABASE_ROOT}\n")

            f.write(f"PACKAGE_ROOT={PACKAGE_PATH}\n")

            f.write(f"DATABASE_URL=postgres://tridentstream@127.0.0.1/tridentstream\n")
            f.write(f"CACHE_URL=dbcache://dbcache\n")
            f.write(f"INSTALLED_APPS=\n")

            f.write(f"HOST=0.0.0.0\n")
            f.write(f"PORT=45477\n")
            f.write(f"PRIVATE_KEY=\n")
            f.write(f"CERT_KEY=\n")


if __name__ == "__main__":
    create_postgres_database()
    create_environ()
    start_postgres()
    install_requirements()
    install_packages()
    bootstrap_tridentstream()
    start_tridentstream()