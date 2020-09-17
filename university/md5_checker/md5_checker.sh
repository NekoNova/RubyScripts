#!/usr/bin/env bash

########################################################################################################################
# This script is a special MD5 checksum script for validating the checksums inside a given folder structure.
# The script is based on the structure and systems used by the Charles University of Prague
#
# Copyright: Arne De Herdt - arne.de.herdt@gmail.com
#
# Permission is granted to the Charles University of Prague to use this script and code for their own usage,
# distribution however to third-parties is prohibited
#
# The following arguments can be passed to the script:
#
#   -p | --path   : The root path where the files are located.
#   -e | --email  : The email to notify when the task is completed.
#
########################################################################################################################

# This function traverses the directory structure from a given path recursively.
# Meaning it will loop over every entry, and dive deeper if it finds a directory.
traverse() {
  for file in "$1"/*; do
    if [ ! -d "${file}" ] ; then
      calculate_checksum "$file"
    else
      traverse "${file}"
    fi
  done
}

# This function will perform the required work to calculate the checksum
calculate_checksum() {
  if [[ ${1: -4} != ".md5" ]]; then
    echo "==> $1 is not an .md5 file, skipping..."
    return
  fi

  if printf '%s\n' "${DB[@]}" | grep -q -e "^$(realpath "$1")|match$"; then
    echo "==> $1 has already been verified, skipping..."
    return
  fi

  if printf '%s\n' "${DB[@]}" | grep -q -e "^$(realpath "$1")|nomatch$"; then
    echo "==> $1 failed verification in the past, re-checking..."
    DB=( "${DB[@]/$(realpath "$1")|nomatch/}" )
  fi

  # Great, we have a file, and it's an MD5 checksum file.
  # This means we need to parse the contents to figure out what's inside.
  echo "==> Analyzing contents of $1"
  CURRENT_DIR=$(dirname "$(realpath "$1")")
  ENTRIES=[]
  IFS=' *' read -ra ENTRIES <<< "$(cat "$1" | tr -d '\r' | tr -d '\n')"
  TIF_FILE=${ENTRIES[1]}
  VERIFICATION_SUM=${ENTRIES[0]}

  echo "    CURRENT_DIR     : $CURRENT_DIR"
  echo "    TIF_FILE        : $TIF_FILE (√)"
  echo "    VERIFICATION_SUM: $VERIFICATION_SUM"

  # Now we can check if the MD5 checksum matches what's in the file.
  CALCULATED_CHECKSUM_ENTRIES=[]
  IFS=' ' read -ra CALCULATED_CHECKSUM_ENTRIES <<< "$(md5sum "$(realpath "$CURRENT_DIR/$TIF_FILE")")"

  echo "    CALCULATED_SUN  : ${CALCULATED_CHECKSUM_ENTRIES[0]}"

  if [ "${CALCULATED_CHECKSUM_ENTRIES[0]}" = "$VERIFICATION_SUM" ]; then
    DB+=("$(realpath "$1")|match")
  else
    DB+=("$(realpath "$1")|nomatch")
  fi
}

# Writes out the log file in the specified root directory, listing all files that didn't match.
# These files are stored inside the DB variable with the |nomatch suffix.
write_log_file() {
  date > "$ROOT_PATH/nomatch.log"

  # Generate log files with all failed entries from our DB
  for i in "${DB[@]}"; do
    # Write out every failed entry, but just the path
    if [[ $i == *"|nomatch"* ]]; then
      echo "${i//|nomatch}" >> "$ROOT_PATH/nomatch.log"
    fi
  done
}

# This function will write out the DB state in our special file.
# However since we might have messed with the data, gaps can exist inside the structure.
# we don't want these gaps, so the function will also clean up the DB
save_db() {
  # First remove all empty entries in the array
  for i in "${!DB[@]}"; do
    if [ "${DB[$i]}" = "" ]; then
      unset 'DB[i]'
    fi
  done

  # Rebuild the indeces so we have consecutive entries
  DB=("${DB[@]}")

  # We have finished traversing the entire directory structure.
  # Make sure we write our new DB state into the file for the next run
  echo "==> Finished parsing all files, saving DB state"
  printf "%s\n" "${DB[@]}" > "$DB_PATH"
}

# This function will send out the email to the user when the task is finished.
# But only when the email has been specified with the script arguments.
send_notification_email() {
  if [ "$EMAIL" != "" ]; then
    LINE_COUNT=$(wc -l "$ROOT_PATH/nomatch.log" | awk '{ print $1 }')
    MINIMUM_LINE_COUNT=1

    if (( LINE_COUNT > MINIMUM_LINE_COUNT )); then
      SUBJECT="[md5_checker] Finished analyzing the files"
      (
        echo "Hello!"
        echo "md5_checker has finished analyzing the files in $ROOT_PATH on server $HOSTNAME"
        echo "Please check the generated nomatch.log file for any issues (attached to this email)"
      ) | mail -s "$SUBJECT" "$EMAIL" -A "$ROOT_PATH/nomatch.log"
    fi
  fi
}

# Our global variables
ROOT_PATH="/proarc/odkladaci_adresar"
DB_PATH="$HOME/.md5_checker/db"
DB=[]
EMAIL=""

# Before we do anything, make sure that our state file exists.
# We will be using this file to write and store the state of our system
if [ ! -f "$DB_PATH" ]; then
  echo "==> State DB could not be found, creating..."
  mkdir -p "$HOME/.md5_checker"
  touch "$DB_PATH"
fi

# Now we need to check if the script has received any arguments, and update our configuration as such.
# This needs to be done before we do any checks or attempts to find files.
# Loop over all arguments provided to the script, and handle their values.
while [[ $# -gt 0 ]] # Loop as long as there is an argument to parse
do
  key="$1" # Take the argument in position 1, and treat is the key, for example --path

  case $key in
    # If a -p or --path is provided, use the second argument as the actual root path for the script.
    -p|--path)
    ROOT_PATH="$2"
    shift
    shift
    ;;
    -e|--email)
    EMAIL="$2"
    shift
    shift
    ;;
  esac
done

echo "==> Initializing md5_checker on $ROOT_PATH"

# Load our database into memory. We will be using this database to check whether a file has already been parsed.
# If there is an entry in the database, then we can skip the file.
mapfile -t DB < "$DB_PATH"

# Perform all the work
traverse "$ROOT_PATH"
save_db
write_log_file
send_notification_email
