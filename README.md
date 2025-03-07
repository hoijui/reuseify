<!--
SPDX-FileCopyrightText: 2023 Robin Vobruba <hoijui.quaero@gmail.com>

SPDX-License-Identifier: CC0-1.0
-->

# REUSE-ify

[![License: AGPL-3.0-or-later](
    https://img.shields.io/badge/License-AGPL--3.0--or--later-blue.svg)](
    https://spdx.org/licenses/AGPL-3.0-or-later.html)
[![REUSE status](
    https://api.reuse.software/badge/github.com/hoijui/reuseify)](
    https://api.reuse.software/info/github.com/hoijui/reuseify)

[![In cooperation with Open Source Ecology Germany](
    https://raw.githubusercontent.com/osegermany/tiny-files/master/res/media/img/badge-oseg.svg)](
    https://opensourceecology.de)

A BASH (and AWK) tool to generate [REUSE] compatible
SPDX licensing info for a project stored in a git repo.

## How it works

It assigns to the projects files:

* **author/copyright** info,
  by extracting it from the git commit history
* **licenses**, using regex + SPDX expression pairs
  defined in a file

The grunt work is done with the [REUSE tool] under the hood.

This tool does not let you execute and forget! \
In any case, you **have to manually adjust**
whatever this script generates!

## Why / What for

[REUSE] is a system by the [Free Software Foundation Europe],
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

You first need to install the original [REUSE tool] by the FSF,
if you don't already have it. \
Then you may continue installing the latest version of reusify:

```sh
git clone "https://github.com/hoijui/reuseify.git"
cd "reuseify/src/software"

# BASH: for new sessions
echo "export PATH=\"$PATH:$(pwd)\"" > ~/.profile
# BASH: for this session
export PATH="$PATH:$(pwd)"
# fish: for this session, all others and after reboot
#fish_add_path (pwd)
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
# Amend the created git commit with your favorite IDE or git GUI.
```

**IMPORTANT** \
If successful, this tool generates a git commit with all the changes,
which you **will have to manually edit** (aka amend)! \

See the next section for an explanation of this commit.

**NOTE** \
It can also be used on already partially annotated projects.

## What it does

It creates a new git commit, that contains:

1. All files that were without REUSE info, should now have it annotated.
2. Those that support header comments, will have it there.
3. Those who do not support header comments,
    will have it duplicated to two locations -
    `${file_path}.license` and `.reuse/dep5` -
    and it is crucial to edit this,
    and make sure it remains only in one of the two,
    and in a cleaned up way,
    especially if you decide to use `.reuse/dep5`,
    you might want to unify entries with clever usage of globs,
    without over-using them.
    You can choose which location to use on a per-file basis.

We do the duplication of annotations described in step 3. above,
to leave ones options open,
and consequently minimizing the required manual work,
to get to what one wants,
basically reducing the required manual work to just deletions.

[REUSE]: https://reuse.software/
[REUSE tool]: https://git.fsfe.org/reuse/tool
[Free Software Foundation Europe]: https://fsfe.org/
