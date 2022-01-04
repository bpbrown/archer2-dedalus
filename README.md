# Installing Dedalus on ARCHER2

Some initial recipes for installing
[Dedalus](https://github.com/DedalusProject/dedalus)
on the new
[ARCHER2](https://www.archer2.ac.uk/) National UK Supercomputing Service.

This version of the build instructions comes out of performance testing Jan 2022 by Ben Brown and Keaton Burns.

## Current recipes

These instructions currently provide the following recipes:

* Recipe 1: Create a Dedalus Python virtual environment, building all packages yourself

* Recipe 2: Create a Dedalus Python virtual environment, using system packages where possible

In testing, we have currently found `Recipe 1` to be much faster than `Recipe 2`.


## Which version of Dedalus to install?

These instructions show you how to install:

* The current Dedalus source code snapshot from its Git repository

## Recipe 1: Create a Dedalus Python virtual environment, building all packages yourself

This creates a Python virtual environment specifically for Dedalus. This allows
you to keep your Dedalus-related Python stuff in one place, separate from your
other Python work.

Start by setting up this `.bash_profile` in your home directory:

```bash
module load cray-python
module load cray-hdf5-parallel
module load cray-fftw

export MPICC=cc
export CC=cc

export FFTW_INCLUDE_PATH=$FFTW_INC
export FFTW_LIBRARY_PATH=$FFTW_DIR
export MPI_PATH=$CRAY_MPICH_DIR

export OMP_NUM_THREADS=1
export NUMEXPR_MAX_THREADS=1

# needed when building with --system-site-packages
export SETUPTOOLS_USE_DISTUTILS=stdlib

export PATH=~/scripts:$PATH

export WORK=${HOME/home/work}

export MPLCONFIGDIR=$WORK/matplotlib

alias dedalus-d2="source $WORK/venvs/dedalus/bin/activate"
```

Either close your shell and log back in, or `source ~/.bash_profile` to make sure you have the right modules and evironment settings.

Then begin the dedalus install.

```bash
mkdir $WORK/venvs
mkdir $WORK/dedalus-build

python -m venv $WORK/venvs/dedalus

dedalus # activate dedalus virtual env
pip install -U pip
pip install -U setuptools
pip install --no-binary=h5py h5py

cd $WORK/dedalus-build
git clone https://github.com/DedalusProject/dedalus.git dedalus
cd dedalus

sed -i -e "/^libraries = \[/s/]/, 'mpi']/" setup.py

cd ..

pip install -e dedalus
```

Your `dedalus-build` directory has been installed with "editable" attributes, and if you update the repo in that directory it should immediately update your pip installed version of dedalus.  The only time this takes some care is if dedalus transposes have changed, in which case you need to re-cythonize `transposes.pyx`. 

## Recipe 2: Create a Dedalus Python virtual environment, using system packages where possible

This creates a Python virtual environment specifically for Dedalus, built with system packages.  In particular, we're using the Cray-provided numpy and scipy.  these are somewhat older versions (currently numpy is 1.18.2 and scipy is 1.4.1 vs 1.22 and 1.7.3 currently), and this limits us to using `master` and not `d3`.  This virtual env is independent from the virtual env built in Recipe 1, though you do need to module swap and reload cray-python before running if you're in the other bash_profile:
```
module swap PrgEnv-cray PrgEnv-gnu
module load cray-python
```

Start by setting up this `.bash_profile` in your home directory:

```bash
module swap PrgEnv-cray PrgEnv-gnu # for dedalus-system build
module load cray-python
module load cray-hdf5-parallel
module load cray-fftw

export FFTW_INCLUDE_PATH=$FFTW_INC
export FFTW_LIBRARY_PATH=$FFTW_DIR
export MPI_PATH=$CRAY_MPICH_DIR

export OMP_NUM_THREADS=1
export NUMEXPR_MAX_THREADS=1

# needed when building with --system-site-packages
export SETUPTOOLS_USE_DISTUTILS=stdlib

export PATH=~/scripts:$PATH

export WORK=${HOME/home/work}

export MPLCONFIGDIR=$WORK/matplotlib

alias dedalus="source $WORK/venvs/dedalus/bin/activate"
alias dedalus-system="source $WORK/venvs/dedalus-system/bin/activate"
```
Major differences are:
1. module swapping to `PrgEnv-gnu`
2. not setting either the `CC` or `MPICC` env variables.  This makes sure we hit `gcc` rather than `cc`.

Either close your shell and log back in, or `source ~/.bash_profile` to make sure you have the right modules and evironment settings (make sure you `unset CC` and `unset MPICC` if you do so).

Then begin the dedalus install.

```bash
mkdir $WORK/venvs
mkdir $WORK/dedalus-build

python -m venv $WORK/venvs/dedalus-system --system-site-packages

dedalus-system # activate dedalus virtual env
pip install -U pip
pip install -U setuptools

# wrap h5py build with correct include path to mpi.h
CFLAGS="-I$CRAY_MPICH_DIR/include" pip install --no-binary=h5py h5py

cd $WORK/dedalus-build
git clone https://github.com/DedalusProject/dedalus.git dedalus-system
cd dedalus-system

sed -i -e "/^libraries = \[/s/]/, 'mpi']/" setup.py

cd ..

pip install -e dedalus-system
```

## Key technical points about these recipes

* Recipe 1 uses Cray compilers, while Recipe 2 uses GCC compilers to match the
  `mpi4py` Python package provided on ARCHER2. The system package was compiled with GCC, as we can
  confirm from:
  ```bash
  ldd $CRAY_PYTHON_PREFIX/lib/python3.8/site-packages/mpi4py/MPI.cpython-38-x86_64-linux-gnu.so
  ...
  libmpi_gnu_91.so.12 => /opt/cray/pe/lib64/libmpi_gnu_91.so.12 (0x00002b0f332e4000)
  ...
  ```

## Example Dedalus submission scripts for ARCHER2

*this section not yet updated*

Here are some example Slurm submission scripts for both recipes:

* For Recipe 1: [rb2d_env.sh](rb2d_venv.sh)
* For Recipe 2: [rb2d_user.sh](rb2d_user.sh)

These use the attached [rayleigh_benard_2d.py](rayleigh_benard_2d.py) example
code, as discussed in:
https://groups.google.com/g/dedalus-users/c/dBCYjjsUe4U/m/WdnOZ9NWBgAJ

You'll need to tweak the submission scripts a wee bit to specify your ARCHER2
account name and possibly some other parameters.

## Deleting your Dedalus installation

Simply delete your Dedalus virtual environment as follows:

```bash
rm -r $WORK/venvs/dedalus
```

or
```bash
rm -r $WORK/venvs/dedalus-system
```
