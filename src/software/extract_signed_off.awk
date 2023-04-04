#!/usr/bin/env -S awk -f
# SPDX-FileCopyrightText: 2023 Robin Vobruba <hoijui.quaero@gmail.com>
# SPDX-License-Identifier: AGPL-3.0-only

# This script extracts author info from commit messages
# containing any number of such lines:
# - Co-authored-by: Firstname Lastname <name@example.com>
# - Signed-off-by: Firstname Lastname <name@example.com>
#
# and prints a CSV table with columns:
# * Year           | string | 2013 - 2018
# * Author <EMail> | string | Jo Doe <jo.doe@email.com>
# This is called from within `reuseify.sh`.
#
# Example:
# $ git log \
#     --follow \
#     --date="format:%Y" \
#     --format="format:@C_START@%n%cd%n%s%n%b%n@C_END@" \
#     -- \
#     "$src_file" \
#     | awk -f extract_signed_off.awk \
#     > year_author.csv

BEGIN {
    inside = 0
    year_set = 0
    #printf "%s,%s\n", "Year", "Author: Firstname Lastname <EMail>"
}

/^@C_START@$/ {
    inside = 1
    year_set = 0
    next
}

/^@C_END@$/ {
    inside = 0
    year_set = 0
    next
}

{
    if (inside && !year_set) {
        year = $0
        year_set = 1
        next
    }
}

/^(Signed-off-by|Co-authored-by): / {
    author = $0
    sub(/^(Signed-off-by|Co-authored-by): /, "", author)
    printf "%s,%s\n", year, author
}