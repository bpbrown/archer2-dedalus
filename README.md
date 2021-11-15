# Installing Dedalus on ARCHER2

Some initial recipes for installing
[Dedalus](https://github.com/DedalusProject/dedalus)
on the new
[ARCHER2](https://www.archer2.ac.uk/) National UK Supercomputing Service.

These instructions were developed for the initial 4-cabinet ARCHER2 system
and will probably need to evolve a bit over time.

## Current recipes

These instructions currently provide the following recipes:

* Recipe 1: Create a Dedalus Python virtual environment
* Recipe 2: Install Dedalus as a user-level Python package

I'd personally recommend using Recipe 1 over Recipe 2.

Note that ARCHER2 doesn't currently provide Anaconda, so we can't install
Dedalus using conda.

## Which version of Dedalus to install?

These instructions show you how to install:

* The current release version (v2.2006) of Dedalus
* The current Dedalus source code snapshot from its Git repository

**NOTE:** I've found that I mostly had to use the latest snapshot of Dedalus
rather than the last production release, as that was giving me
`Objects are not all equal`
errors at the end of the run. This seems to be a known issue.

In particular, the `rayleigh_benard_2d.py` example code only works correctly
with the current Git snapshot.

## Recipe 1: Create a Dedalus Python virtual environment

This creates a Python virtual environment specifically for Dedalus. This allows
you to keep your Dedalus-related Python stuff in one place, separate from your
other Python work.

```bash
module restore PrgEnv-cray  # Restore modules to defaults
module load cray-python  # Load Python module

# Create virtual environment in my /work/... directory
export WORK=${HOME/home/work}  # (This converts my home dir to corresponding work dir: /work/[proj]/[proj]/[username])
mkdir -p $WORK/venvs
python -m venv $WORK/venvs/dedalus

# Activate virtual environment
source $WORK/venvs/dedalus/bin/activate
pip install -U pip  # Upgrade pip to latest version

# Build & install h5py, linked to Cray HDF5 libraries, compiled using Cray compiler (CC=cc)
module load cray-hdf5-parallel
CC=cc pip install --no-binary=h5py h5py
module unload cray-hdf5-parallel

# Build and install mpi4py, again compiling from source rather than using a binary
MPICC=cc pip install --no-binary=mpi4py mpi4py

# Create a temporary directory for building Dedalus.
# For example:
cd $WORK
mkdir -p dedalus-build
cd dedalus-build

# Now do ONE of the following:
#
# (1) Download the latest source code snapshot from Git
git clone https://github.com/DedalusProject/dedalus
cd dedalus

# OR (2) Download and extract the latest (v2.2006) Dedalus source tarball:
wget https://github.com/DedalusProject/dedalus/archive/v2.2006.tar.gz
tar xf v2.2006.tar.gz
cd dedalus-2.2006

# Patch Dedalus' setup.py to add explicit MPI library dependency
sed -i -e "/^libraries = \[/s/]/, 'mpi']/" setup.py

# Build Dedalus extension libraries
module load cray-fftw
export FFTW_PATH=$CRAY_FFTW_PREFIX
export MPI_PATH=$CRAY_MPICH_BASEDIR/cray/$PE_MPICH_GENCOMPILERS_CRAY
CC=cc pip install .
module unload cray-fftw
```

After a successful installation, you might now want to delete your
`dedalus-build` directory.

## Recipe 2: Build & install Dedalus at user level

This recipe installs Dedalus as a user-level Python package.

```bash
export WORK=${HOME/home/work}  # Converts home dir to corresponding work dir
export PYTHONUSERBASE=$WORK/.local  # Recommended in ARCHER2 docs for user-level Python package installation

# We'll use the GNU compilers here, as ARCHER2's existing mpi4py
# package was compiled with GCC.
module restore PrgEnv-gnu

# Activate Python
module load cray-python

# Build & install h5py, linked to Cray HDF5 libraries.
# (We need to help GCC find mpi.h, hence the CFLAGS="..." stuff.)
module load cray-hdf5-parallel
CFLAGS="-I$CRAY_MPICH_BASEDIR/gnu/$PE_MPICH_GENCOMPILERS_GNU/include" pip install --user --no-binary=h5py h5py
module unload cray-hdf5-parallel

# Create a temporary directory for building Dedalus.
# For example:
cd $WORK
mkdir -p dedalus-build
cd dedalus-build

# Now do ONE of the following:
#
# (1) Download the latest source code snapshot from Git
git clone https://github.com/DedalusProject/dedalus
cd dedalus

# OR (2) Download and extract the latest (v2.2006) Dedalus source tarball:
wget https://github.com/DedalusProject/dedalus/archive/v2.2006.tar.gz
tar xf v2.2006.tar.gz
cd dedalus-2.2006

# Patch Dedalus' setup.py to add explicit MPI library dependency
sed -i -e "/^libraries = \[/s/]/, 'mpi']/" setup.py

# Build Dedalus extension libraries
module load cray-fftw
export FFTW_PATH=$CRAY_FFTW_PREFIX
export MPI_PATH=$CRAY_MPICH_BASEDIR/gnu/$PE_MPICH_GENCOMPILERS_GNU
python setup.py install --user  # FIXME: This works fine, but running setup.py is no longer considered best practice
#pip install --user .  # FIXME: This alternative does not work - it tries to install mpi4py from scratch
module unload cray-fftw

# (For tidiness, let's revert back to default Cray compilers)
module restore PrgEnv-cray
```

After a successful installation, you might now want to delete your
`dedalus-build` directory.

## Key technical points about these recipes

* I chose to use the Cray compiler for Recipe 1. (I also tried the GCC
  compilers but haven't been able to get this to work yet.)
* However, I had to use the GCC compilers for Recipe 2 in order to match the
  `mpi4py` Python package provided on ARCHER2 was compiled with GCC, as we can
  confirm from:
  ```bash
  ldd $CRAY_PYTHON_PREFIX/lib/python3.8/site-packages/mpi4py/MPI.cpython-38-x86_64-linux-gnu.so
  ...
  libmpi_gnu_91.so.12 => /opt/cray/pe/lib64/libmpi_gnu_91.so.12 (0x00002b0f332e4000)
  ...
  ```
  I found that I needed to use the same MPI libraries for Dedalus, otherwise
  we'd get a blow-up at runtime.
* I wasn't able to get a working Dedalus using the standard `pip install dedalus`
  method - this was giving a runtime blow-up at one of Dedalus' internal imports:
  ```bash
  python -c 'import dedalus.libraries.fftw'
  ImportError: /opt/cray/pe/fftw/3.3.8.8/x86_rome/lib/libfftw3_mpi.so.mpi31.3: undefined symbol: MPI_Alltoallv
  ```
  These `MPI_*` symbols are provided by the MPI libraries but left
  unresolved in the FFTW3 libraries, and something here is really not liking
  that. Hence those `sed` commands in the recipes, which patch Dedalus' library
  dependencies to explicitly require MPI.
* These recipes perform an explicit installation of the Python `h5py` library,
  explicitly linking to the Cray HDF5 libraries. Doing a standard
  `pip install ...` builds and installs local HDF5 libraries, which we'd
  expect to be less performant than Cray's libraries.
* The `cray-mpich` module is activated by default on ARCHER2, so I've just
  decided to use that here.

## Example Dedalus submission scripts for ARCHER2

Here are some example Slurm submission scripts for both recipes:

* For Recipe 1: [rb2d_env.sh](rb2d_venv.sh)
* For Recipe 2: [rb2d_user.sh](rb2d_user.sh)

These use the attached [rayleigh_benard_2d.py](rayleigh_benard_2d.py) example
code, as discussed in:
https://groups.google.com/g/dedalus-users/c/dBCYjjsUe4U/m/WdnOZ9NWBgAJ

You'll need to tweak the submission scripts a wee bit to specify your ARCHER2
account name and possibly some other parameters.

## Deleting your Dedalus installation

### For Recipe 1

Simply delete your Dedalus virtual environment as follows:

```bash
rm -r $WORK/venvs/dedalus
```

This is another reason why Recipe 1 is better than Recipe 2!

### For Recipe 2

You can delete your locally-installed Dedalus package with:

```bash
pip uninstall dedalus
```

However, Dedalus will probably have installed a bunch of additional packages
and, if you've installed other packages locally, it may not be obvious which
of these additional packages can now be safely deleted.
