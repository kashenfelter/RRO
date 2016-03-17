
# set -x
#
# Cross platform script to load and run IOQR
#
# Assumes:
#  The instance of R being tested is at the working directory under  R-*
#
# Returns 0 if tests run
# Writes "...FAILED!!" if any tests fail
# Otherwise returns non zero if something runs and returns non zero.
#
# Side effects: Produces html, txt, and xml test reports in the folder from which the script command was issued.
# These reports are used as input to the test reporting system.
#

# Exit if anything returns non zero
set -o errexit

# exit on uninitialized variable
set -u
# set -x
echo ================================
echo running IOQR
echo =========================
set
echo =========================

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

## TODO Need a definitive way of determining what R version we should be picking up
##
echo Check to see if IOQR package is installed, remove it if so
Rscript -e "if('IOQR' %in% rownames(installed.packages()) == TRUE) {remove.packages('IOQR')}"

##
## TODO:  Get RUnit from nuget rather than cran
echo Install RUnit
Rscript -e "install.packages('http://cran.revolutionanalytics.com/src/contrib/Archive/RUnit/RUnit_0.4.26.tar.gz')"

##
rm -f IOQR_*.tar.gz
echo Build IOQR package
R CMD build ${DIR}/../IOQR/pkg

##
echo Install IOQR package
R CMD INSTALL IOQR_*.tar.gz
BASENAME="IOQR_${PLATFORM}"

##
cat > RunIOQR.R <<EOF
library("IOQR")

ret <- IOQR( outdir=getwd(),
     basename="${BASENAME}",
#     testFileRegexp="runit.package.loadability.R",
#     testFuncRegexp="test.reg.plot.stress",
     printJUnit=FALSE,
     view=FALSE )
if (ret) {
    cat( "All tests passed\n" )
} else {
    cat( "One or more test FAILED!!\n" )
}
quit(status=0)
EOF

echo
echo Run IOQR
Rscript RunIOQR.R 2>&1 | tee ${BASENAME}.log

retval=`grep -s -c 'FAILED!!' ${BASENAME}.log || true`
echo IOQR.sh retval: $retval
exit $retval
