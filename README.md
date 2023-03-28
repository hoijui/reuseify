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

A BASH (and AWK) tool to generate [REUSE](https://reuse.software/) compatible
SPDX licensing info
for a project stored in a git repo.
It uses the git commit history for extracting author/copyright info,
and a file assigning regexes - matching the (git tracked/content) files -
to SPDX expressions.

This tool does not let you execute and forget! \
In any case, you **have to manually adjust**
whatever this script generates!

## Why / What for

[REUSE](https://reuse.software/) is a system by
the [Free Software Foundation Europe](https://fsfe.org/),
for assigning detailed (per file) licensing information for a project,
both human- and machine-readable.
In other words, it is like your *LICENSE* file on steroids.

There are many good reasons to do this, but we will assume now,
that you are already convinced it is a good idea to have that.

If you start a new project, you can add REUSE info to it from the start.
If you want to convert an existing project however,
things are a bit more difficult:
There are a lot of files already,
probably edited by many people over years,
sometimes renamed or moved to different directories, ...
How to handle this; how to correctly annotate each file now?

This is where this project comes in.
Instead of manually extracting the list of authors for each file
and the years they were active,
plus deciding on the license for each file,
this script helps you automate as much of this as possible. \
Always remember though,
that this only relieves you of the labor-intensive grit-work,
and not of any legal questions or from **manually checking
if the generated info actually makes sense**.

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
which you **will have to manually edit** (aka amend)! \
See the output of the tool for hints of what to look for.
