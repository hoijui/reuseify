#!/usr/bin/env -S awk -f
# SPDX-FileCopyrightText: 2023 Robin Vobruba <hoijui.quaero@gmail.com>
# SPDX-License-Identifier: AGPL-3.0-only

# This script takes as intput the output of `reuse spdx`,
# and prints a CSV table with columns:
# * File-Path     | string     | src/mech/part_x/main.fcstd
# * Has-License   | bool (0|1) | 1
# * Has-Copyright | bool (0|1) | 0
# This is called from within `reuseify.sh`.
#
# Example:
# $ reuse spdx | filter_unlicensed_files.awk > file_hasLicense_hasCopyright.csv

function finalize_file_entry()
{
    if (at_file) {
        printf "%s,%d,%d\n", file_path, has_license, has_copyright
    }
    at_file = 0
    file_path = ""
    has_license = 0
    has_copyright = 0
}

function check_license(license)
{
    if (at_file) {
        #license = $2
		if (license != "NOASSERTION") {
            has_license = 1
        }
    }
}

function check_copyright(copyright)
{
    if (at_file) {
        #copyright = $2
		if (copyright != "NONE") {
            has_copyright = 1
        }
    }
}

BEGIN {
    at_file = 0
    printf "%s,%s,%s\n", "File-Path", "Has-License", "Has-Copyright"
}

/^$/ {
    finalize_file_entry()
}

/^FileName: \.\// {
    at_file = 1
    file_path = $2
    # Removes the initial "./", if present
    sub(/^\.\//, "", file_path)
}

/^LicenseConcluded: / {
    if (at_file) {
        check_license($2)
    }
}

/^LicenseInfoInFile: / {
    if (at_file) {
        check_license($2)
    }
}

/^FileCopyrightText: / {
    if (at_file) {
        check_copyright($2)
    }
}

END {
    finalize_file_entry()
}