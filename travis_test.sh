# Use python, pip from build virtualenv
export PATH=$PWD/../build/venv/bin:$PATH
echo "Python on path: `which python`"
echo "pip on path: `which pip`"

WHEELHOUSE=$PWD/../build/wheelhouse

pip install -q nose

# Return code
RET=0

echo "sanity checks"
python -c "import sys; print('\n'.join(sys.path))"
if [ $? -ne 0 ] ; then RET=1; fi

function simple_import {
    pkg=$1
    python -c "import ${pkg}; print(${pkg}.__version__, ${pkg}.__file__)"
    if [ $? -ne 0 ] ; then RET=1; fi
}

function unit_test {
    pkg=$1
    arch=$2
    test_str="import sys; import ${pkg}; sys.exit(not ${pkg}.test(verbose=0).wasSuccessful())"
    arch $arch python -c "$test_str"
    if [ $? -ne 0 ] ; then RET=1; fi
}

echo "unit tests"
if [[ $PACKAGES =~ "scipy" ]]; then
    if [ -n "$UPGRADE_NP" ]; then
        pip install -q --upgrade numpy
    fi
    # Install scipy from wheel
    pip install $WHEELHOUSE/scipy*.whl
    simple_import numpy
    simple_import scipy
    unit_test scipy -x86_64
    # If we're going to test with new numpy later, skip i386 tests to save
    # time, otherwise travis will time out (50 minute cutoff)
    if [[ ! $PACKAGES =~ "numpy" ]]; then
        unit_test scipy -i386
    fi
fi
if [[ $PACKAGES =~ "numpy" ]]; then
    pip install $WHEELHOUSE/numpy*.whl
    simple_import numpy
    unit_test numpy -x86_64
    unit_test numpy -i386
    if [[ $PACKAGES =~ "scipy" ]]; then
        simple_import scipy
        unit_test scipy -x86_64
        unit_test scipy -i386
    fi
fi

echo "done testing numpy, scipy"

# Set the return code
(exit $RET)
