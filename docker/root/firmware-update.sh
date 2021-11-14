#!/bin/bash

# ===========================
# Configuration
# ===========================
VERSION=0.8
# ---------------------------
# Flasher and options
# ---------------------------
FLASHER=/usr/bin/GCFFlasher_internal
FLASHER_PARAM_LIST=( -d -f -s -t -R -B -x )
typeset -A FLASHER_PARAM_NAMES=( # GCFFlasher <options>
                                 #  -r              force device reset without programming
    [-f]="Firmware file"         #  -f <firmware>   flash firmware file
    [-d]="Device path ."         #  -d <device>     device number or path to use, e.g. 0, /dev/ttyUSB0 or RaspBee
    [-s]="Serial number"         #  -s <serial>     serial number to use
    [-t]="Timeout ....."         #  -t <timeout>    retry until timeout (seconds) is reached
    [-R]="Retries ....."         #  -R <retries>    max. retries
    [-B]="Baudrate ...."         #  -B <baudrate>   custom baudrate
                                 #  -l              list devices
    [-x]="Loglevel ...."         #  -x <loglevel>   debug log level 0, 1, 3
                                 #  -j <test>       runs a test 1
                                 #  -h -?           print this help
)
typeset -A FLASHER_PARAM_PRINT=(
    [-f]="[^/]*$"
    [default]=".*"
)
# Default values
typeset -A FLASHER_PARAM_VALUES=(
    [-d]="$DECONZ_DEVICE"
    [-t]="60"
)

# ---------------------------
# Firmware details
# ---------------------------
FW_PATH=/usr/share/deCONZ/firmware/
typeset -A FW_ONLINE_BASES=(
    [stable]="http://deconz.dresden-elektronik.de/deconz-firmware/"
    [beta]="http://deconz.dresden-elektronik.de/deconz-firmware/beta/"
)
FW_ONLINE_BASE_ORDER=( stable beta )

# ===========================
# exit functions
# ===========================
# ---------------------------
# Exit the script
# - on exit print 1st param or "Exiting..." as message
# - use 2nd param or 1 as exit-code
# ---------------------------
function exit_with_error() {
    typeset msg="${1:-Exiting...}"
    typeset -i retVal="${2:-1}"
    printf "\n%s\n\n" "$msg"
    exit $retVal
}

# ---------------------------
# Check last return-code or 2nd param
# - if non-zero exit with message
# - on exit print 1st param or "Exiting..." as message
# ---------------------------
function exit_on_error() {
    typeset -i retVal="${2:-$?}"
    typeset msg="$1"
    (( retVal == 0 )) || exit_with_error "$msg" $retVal
}

# ---------------------------
# Check last return-code or 3rd param
# - if non-zero exit with message
# - on exit remove file (1st param) if present
# - on exit print 2nd param or "Exiting..." as message
# ---------------------------
function delete_and_exit_on_error() {
    typeset -i retVal="${3:-$?}"
    typeset file="$1"
    typeset msg="$2"
    if (( retVal != 0 )); then
        [[ -f $file ]] && rm "$file"
        exit_with_error "$msg" $retVal
    fi
}

# ---------------------------
# Check 1st param as user-input
# - exit script on empty input
# ---------------------------
function exit_on_enter() {
    typeset input="$1"
    [[ -n $input ]] || exit_with_error
}

# ===========================
# utility functions
# ===========================
# ---------------------------
# Parse all options passed to the script.
# Options of the flasher are valid options.
# ---------------------------
function parse_options() {
    while (( $# > 0)); do
        [[ -n ${FLASHER_PARAM_NAMES[$1]} ]] || exit_with_error "Unknown argument '$1'. Exiting ..."
        FLASHER_PARAM_VALUES[$1]="$2"
        shift 2
    done
}

echo "-------------------------------------------------------------------"
echo " "
echo "             deconzcommunity/deconz Firmware Flashing Script"
echo " "
echo "                       Version: $VERSION"
echo " "
echo "-------------------------------------------------------------------"
echo " "

parse_options "$@"

echo " "
echo "Listing attached devices..."
echo " "

$FLASHER -l

echo " "
echo "Enter the full device path, or press Enter now to exit."
echo " "

param=-d
read -ep "${FLASHER_PARAM_NAMES[$param]}: " -i "${FLASHER_PARAM_VALUES[$param]}" FLASHER_PARAM_VALUES[$param]
exit_on_enter ${FLASHER_PARAM_VALUES[$param]}

echo " "
echo "-------------------------------------------------------------------"
echo " "
echo "Firmware available for flashing:"
ls -1 "$FW_PATH"

echo " "
echo "Enter the firmware file name from above, including extension."
echo "Alternatively, you may enter the name of a firmware file to download"
echo "from any of the following sources:"
for base in "${FW_ONLINE_BASE_ORDER[@]}"; do
    printf " - %-60s (%s)\n" "${FW_ONLINE_BASES[$base]}" "$base"
done
echo " "
echo "If you wish to exit, just hit Enter."
echo " "

param=-f
read -ep "${FLASHER_PARAM_NAMES[$param]}: " -i "${FLASHER_PARAM_VALUES[$param]##*/}" fileName
exit_on_enter $fileName
FLASHER_PARAM_VALUES[$param]="${FW_PATH%/}/$fileName"

echo " "
if [[ ! -f ${FLASHER_PARAM_VALUES[-f]} ]]; then
    for base in "${FW_ONLINE_BASE_ORDER[@]}"; do
        fw_url="${FW_ONLINE_BASES[$base]%/}/$fileName"
        curl --fail --silent --head --output /dev/null "$fw_url" && break
    done
    exit_on_error "Can't find '$fileName' neither locally nor online. Exiting ..."
    read -ep "File not found locally. Enter Y to download from ${fw_url}: " answer
    [[ $answer == [yY] ]] || exit_with_error

    echo " "
    echo "Downloading..."
    echo " "
    curl --fail --output "${FLASHER_PARAM_VALUES[-f]}" "${fw_url}" && [[ -f ${FLASHER_PARAM_VALUES[-f]} ]]
    delete_and_exit_on_error "${FLASHER_PARAM_VALUES[-f]}" "Download Error! Please re-run this script..."
    echo " "
    echo "Download complete! Checking md5 checksum..."
    md5=$(curl --fail --silent "${fw_url}.md5")
    [[ -n $md5 ]] || delete_and_exit_on_error "${FLASHER_PARAM_VALUES[-f]}" "Checksum file '${fileName}.md5' not found! Please re-run this script..."
    echo "${md5% *} ${FLASHER_PARAM_VALUES[-f]}" | md5sum --check
    delete_and_exit_on_error "${FLASHER_PARAM_VALUES[-f]}" "Error comparing checksums! Please re-run this script..."
    echo " "
fi

echo "-------------------------------------------------------------------"
echo " "
FLASHER_PARAMS=()
for param in "${FLASHER_PARAM_LIST[@]}"; do
    value="${FLASHER_PARAM_VALUES[$param]}"
    [[ -n $value ]] || continue
    FLASHER_PARAMS+=( "$param" "$value" )

    pattern="${FLASHER_PARAM_PRINT[$param]-${FLASHER_PARAM_PRINT[default]}}"
    [[ $value =~ $pattern ]] && printf "%s: %s\n" "${FLASHER_PARAM_NAMES[$param]}" "${BASH_REMATCH}"
done

echo " "
echo "Are the above values correct?"
read -ep "Enter Y to proceed, any other entry to exit: " correctVal
[[ $correctVal == [yY] ]] || exit_with_error

echo " "
echo "Flashing..."
echo " "
$FLASHER "${FLASHER_PARAMS[@]}"
exit_on_error "Flashing Error! Please re-run this script..."
