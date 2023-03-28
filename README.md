<!--
SPDX-FileCopyrightText: 2023 Robin Vobruba <hoijui.quaero@gmail.com>

SPDX-License-Identifier: CC0-1.0
-->

# REUSE-ify

[![License: AGPL-3.0-or-later](
    https://img.shields.io/badge/License-AGPL--%203.0--or--later-blue.svg)](
    https://spdx.org/licenses/AGPL-3.0-or-later.html)
[![REUSE status](
    https://api.reuse.software/badge/github.com/hoijui/reuseify)](
    https://api.reuse.software/info/github.com/hoijui/reuseify)

A BASH (and AWK) tool to generate REUSE compatible SPDX licensing info
for a project stored in a git repo.
It uses the git commit history for extracting author/copyright info,
and a file assigning regexes - matching the (git tracked/content) files -
to SPDX expressions.

This tool does not let you execute and forget! \
In any case, you **have to manually adjust**
whatever this script generates!

## Installation

```sh
git clone "https://github.com/hoijui/reuseify.git"
cd "reuseify/src/software"

# To use it permanently
echo "export PATH=\"$PATH:$(pwd)\"" > ~/.profile

# To use it for this session
export PATH="$PATH:$(pwd)"
```

to update:

```sh
cd reuseify
git pull
```

## Usage

```sh
cd my-git-project
reuseify.sh --init
# Manually edit file '.reuseify/license_rgxs.tsv'.
reuseify.sh
# Ammend the created git commit with your favourite IDE or git GUI.
```

**IMPORTANT** \
If successful, this tool generates a git commit with all the changes,
which you *will have to* manually edit (aka amend)!
