#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2023-2025 Robin Vobruba <hoijui.quaero@gmail.com>
# SPDX-License-Identifier: AGPL-3.0-only
#
# See the output of "$0 -h" for details.

# Exit immediately on each error and unset variable;
# see: https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -Eeuo pipefail
#set -eu

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
script_dir="$(dirname "$script_path")"
script_name="$(basename "$script_path")"
our_dir=".reuseify"
rgx_file="$our_dir/license_rgxs.tsv"
find_unlicensed_awk="$script_dir/filter_unlicensed_files.awk"
extract_signed_off_awk="$script_dir/extract_signed_off.awk"
tmp_file_statuses="$our_dir/file_statuses.csv"
init=false
re_author=false
dry=false

function print_help() {

	echo -n "$script_name -"
	echo "Adds REUSE (SPDX) license info to a git repo."
	echo "It gets the authors from the git history of each individual file,"
	echo "and the license from a CSV/TSV file with repo-relative regex ('$rgx_file')."
	echo
	echo "Usage:"
	echo "  $script_name [OPTION...]"
	echo "Options:"
	echo "  -h, --help              Print this usage help and exits."
	echo "  -i, --init              Initializes this repo for use with this tool and exits."
	echo "  -r, --re-author         Also adds additional author annotations to files"
	echo "                          that already are author annotated."
	echo "  -d, --dry               Does not actually change anything,"
    echo "                          just prints-out commands that would be executed."
	echo "Examples:"
	echo "  $script_name --help"
	echo "  $script_name --init"
	echo "  $script_name --dry"
	echo "  $script_name"
}

# read command-line args
POSITIONAL=()
while [[ $# -gt 0 ]]
do
	arg="$1"
	shift # $2 -> $1, $3 -> $2, ...

	case "$arg" in
		-h|--help)
			print_help
			exit 0
			;;
		-i|--init)
			init=true
			;;
		-r|--re-author)
			re_author=true
			;;
		-d|--dry)
			dry=true
			;;
		*) # non-/unknown option
			POSITIONAL+=("$arg") # save it in an array for later
			;;
	esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

function get_authors() {
    local src_file="$1"
    {
        # This lists the commit authors
        git log \
            --follow \
            --date="format:%Y" \
            --format="format:%cd,%aN <%aE>" \
            -- \
            "$src_file"
        echo

        # This lists "Signed-off-by: ..." and "Co-authored-by: ..." authors
        git log \
            --follow \
            --date="format:%Y" \
            --format="format:@C_START@%n%cd%n%s%n%b%n@C_END@" \
            -- \
            "$src_file" \
            | awk -f "$extract_signed_off_awk"
    } | awk '!seen[$0]++'
}

function decide_license_for() {
    local src_file="$1"
    local length=${#license_rgxs[@]}
    for (( j = 0; j < length; j++ ))
    do
        if echo "$src_file" | grep -E -e "^${license_rgxs[$j]}\$" --quiet
        then
            echo "${license_spdx_ids[$j]}"
            return 0
        fi
    done
    return 1
}

function exit_if_not_git_repo() {
    if [ -e ".git" ]
    then
        echo "INFO: Git working directory found; continuing ..."
    else
        >&2 echo "ERROR: Git working directory is *NOT* found."
        >&2 echo "ERROR: You may want to run 'git init'."
        exit 7
    fi
}

function exit_if_git_unclean() {
    if [ -z "$(git status --porcelain)" ]
    then
        echo "INFO: Git working directory is clean; continuing ..."
    else
        >&2 echo "ERROR: Git working directory is *NOT* clean, aborting."
        >&2 echo "ERROR: Please check the output of 'git status'."
        exit 1
    fi
}

function exit_if_missing_rgxs() {
    if [ -f "$rgx_file" ]
    then
        echo "INFO: Using file '$rgx_file' to determine which license to use for which file."
    else
        >&2 echo "ERROR: Could not find file '$rgx_file' - it is required!"
        exit 2
    fi
}

function init_repo() {
    mkdir -p "$our_dir"

    if ! [ -f "$rgx_file" ]
    then
        {
            printf "%s\t%s\n" 'Regex' 'SPDX-License-ID'
            printf "%s\t%s\n" '.*\.md' 'CC-BY-SA-4.0'
            printf "%s\t%s\n" '\.git(ignore|module|attributes)' 'CC0-1.0'
            printf "%s\t%s\n" 'run/.*' 'Unlicense'
            printf "%s\t%s\n" 'src/software/.*' 'AGPL-3.0-or-later'
            printf "%s\t%s\n" 'res/.*' 'CC-BY-SA-4.0'
            printf "%s\t%s\n" '.*' 'CERN-OHL-S-2.0'
        } > "$rgx_file"
        >&2 echo "WARN: Generated sample '$rgx_file'; please edit it!"
    fi

    exclude_file='.git/info/exclude'
    if ! grep -q '^/'"$our_dir"'/$' "$exclude_file"
    then
        echo "/$our_dir/" >> "$exclude_file"
        echo "INFO: Added folder '$our_dir' to this repos local git ignore file ('$exclude_file')."
    fi
}

function reuse_annotate() {
    local file_path="$1"
    shift

    if ! $mod_cmd_prefix reuse annotate \
        "$@" \
        --merge-copyrights \
        --multi-line \
        "$file_path" \
        2> /dev/null
    then
        # Try without --multi-line
        if ! $mod_cmd_prefix reuse annotate \
            "$@" \
            --merge-copyrights \
            "$file_path" \
            2> /dev/null
        then
            # Try with --force-dot-license
            $mod_cmd_prefix reuse annotate \
                "$@" \
                --merge-copyrights \
                --force-dot-license \
                "$file_path"
        fi
    fi
}

function add_dep5() {
    local file_path="$1"
    shift
    local license="$1"
    shift

    dep5=".reuse/dep5"
    local write_header=false
    if ! [ -e "$dep5" ]
    then
        mkdir -p "$(dirname "$dep5")"
        write_header=true
    fi
    {
        if $write_header
        then
            if ! which projvar > /dev/null
            then
                >&2 echo "WARN:  [\`projvar\`](https://github.com/hoijui/projvar) not found;"
                >&2 echo "WARN:  we will use stub entries for the dep5 file header."
            else
                local tmp_projvar_file="/tmp/reusify_projvar_$RANDOM"
                if projvar --file-out "$tmp_projvar_file"
                then
                    # shellcheck source=/dev/null
                    source "$tmp_projvar_file"
                fi
                rm -f "$tmp_projvar_file"
            fi
            local project_name="${PROJECT_NAME:-"TODO_ProjectName"}"
            local project_contact="TODO_FirstName TODO_LastName (TODO_optional_Organization) <TODO@TODO.TODO>"
            local project_url="${PROJECT_REPO_WEB_URL:-"https://gitTODO.com/TODO/TODO"}"
            echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/"
            echo "Upstream-Name: $project_name"
            echo "Upstream-Contact: $project_contact"
            echo "Source: $project_url"
        fi

        echo
        echo "Files: $file_path"
        echo "Copyright:"
        for cpr in "$@"
        do
            echo "    $cpr"
        done
        echo "License: $license"
    } >> "$dep5"
}

function process_file() {
    local file_path="$1"
    local has_license="$2"
    local has_copyright="$3"

    local license
    if [ "$has_license" -eq 0 ]
    then
        # License is missing -> add it
        if ! license="$(decide_license_for "$file_path")"
        then
            >&2 echo "ERROR: No copyright regex matched file '$file_path';"
            >&2 echo "ERROR: Please edit '$rgx_file' accordingly."
            exit 4
        fi
        reuse_annotate \
            "$file_path" \
            --license "$license"
    fi
    if [ "$has_copyright" -eq 0 ]
    then
        # Copyright is missing -> add it
        num_authors=0
        while IFS="," read -r year author
        do
            reuse_annotate \
                "$file_path" \
                --year "$year" \
                --copyright "$author"
            num_authors=$(( num_authors + 1 ))
        done < <(get_authors "$file_path")
        if [ "$num_authors" -eq 0 ]
        then
            >&2 echo "ERROR: Not a single author found for file '$file_path'."
            exit 5
        fi
    fi

    # If the associated *.license file was touched (or existed already),
    # copy its info to the dep5 file.
    local lic_file_path="${file_path}.license"
    local copyrights
    if [ -f "$lic_file_path" ]
    then
        readarray -t copyrights < <(awk -F ": " '/^SPDX-FileCopyrightText: / { print $2; }' < "$lic_file_path")
        num_cr_entries="${#copyrights[@]}"
        if [ "$num_cr_entries" -eq 0 ]
        then
            >&2 echo "ERROR: Not a single copyright entry found for file '$file_path'; found $num_cr_entries."
            exit 6
        fi
        license="${license:-"$(decide_license_for "$file_path")"}"
        add_dep5 \
            "$file_path" \
            "$license" \
            "${copyrights[@]}"
    fi
}

exit_if_not_git_repo

exit_if_git_unclean

if $init
then
    init_repo
    exit 0
fi

exit_if_missing_rgxs

mod_cmd_prefix=''
if $dry
then
    mod_cmd_prefix='echo'
fi

license_rgxs=() 
license_spdx_ids=() 
while IFS=$'\t' read -r rgx spdx_id
do
    echo "|$rgx|$spdx_id|"
    if [ "$rgx" = 'Regex' ]
    then
        # This is the header row; skip it
        continue
    fi
    if [  "${rgx:0:1}" = '#' ]
    then
        # This is a comment; skip it
        continue
    fi
    license_rgxs+=("$rgx")
    license_spdx_ids+=("$spdx_id")
done < <(cat "$rgx_file")

reuse spdx | \
    awk -f "$find_unlicensed_awk" \
    > "$tmp_file_statuses"

while IFS="," read -r file_path has_license has_copyright
do
    if $re_author
    then
        has_copyright="0"
    fi
    echo
    echo "Ensuring REUSE info for '$file_path' ..."
    process_file "$file_path" "$has_license" "$has_copyright"
done < <(tail -n +2 "$tmp_file_statuses")

rm "$tmp_file_statuses"

reuse download --all

git add --all
git commit -a -m "REUSE licensing info - auto-generated with \`$script_name\`"
new_commit="$(git describe --always)"

echo
echo "Created a new git commit '$new_commit'."
>&2 echo "WARN: Please modify (amend) the new git commit!"
>&2 echo "WARN: Take special care looking at '.reuse/dep5'"
>&2 echo "WARN: and all the *.license files in the commit."
echo
echo "done."
