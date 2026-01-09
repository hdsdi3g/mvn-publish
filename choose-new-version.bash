#!/bin/bash
#
#    publish - shortcuts for Git and Maven in an interactive script
#    Copyright (C) hdsdi3g for hd3g.tv 2021
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or any
#    later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program. If not, see <https://www.gnu.org/licenses/>.
#
#    Usage: choose-new-version.bash <current version>
#    Return the new version, or nothing.
#
#    You must have a valid setup of:
#       - bc

set -eu

POM_VERSION="$1";
IS_MAIN_BRANCH="$2";
ACTUAl_BRANCH="$3";

if [[ "$POM_VERSION" =~ .*"SNAPSHOT".*  ]]; then
	POM_BASE_VERSION=${POM_VERSION:0:-9};
else
	POM_BASE_VERSION=$POM_VERSION
fi
MAJ=$(echo $POM_BASE_VERSION | cut -d "." -f 1);
MIN=$(echo $POM_BASE_VERSION | cut -d "." -f 2);
PATCH=$(echo $POM_BASE_VERSION | cut -d "." -f 3);
INCR_MAJ=$(echo $MAJ+1 | bc)".0.0"
INCR_MIN="$MAJ."$(echo $MIN+1 | bc)".0"
INCR_PATCH="$MAJ.$MIN."$(echo $PATCH+1 | bc)

cmd=(whiptail --title "Select pom.xml version to up set" --menu "Which version should we go to, from the actual $POM_VERSION?" 0 0 0);
if [[ "$POM_VERSION" =~ .*"SNAPSHOT".*  ]]; then
    cmd+=("$POM_VERSION" "Keep current opened version")
    cmd+=("$POM_BASE_VERSION" "Close current version")
    if [[ "$IS_MAIN_BRANCH" == "0" ]]; then
        cmd+=("TESTS" "Do a simple clean test on $ACTUAl_BRANCH")
        cmd+=("PR" "Create a new GitHub Pull Request for branch $ACTUAl_BRANCH")
        cmd+=("TESTS_PR" "Create a new GitHub Pull Request for branch $ACTUAl_BRANCH and do a simple clean test")
    fi
    cmd+=("$INCR_PATCH-SNAPSHOT" "Open new patch version")
    cmd+=("$INCR_MIN-SNAPSHOT" "Open new minor version")
    cmd+=("$INCR_MAJ-SNAPSHOT" "Open new major version")
    cmd+=("$INCR_PATCH" "Close to new patch version")
    cmd+=("$INCR_MIN" "Close to new minor version")
    cmd+=("$INCR_MAJ" "Close to new major version")
else
    cmd+=("$POM_VERSION" "Keep current version")
    cmd+=("$INCR_PATCH-SNAPSHOT" "Open new patch version")
    cmd+=("$INCR_MIN-SNAPSHOT" "Open new minor version")
    cmd+=("$INCR_MAJ-SNAPSHOT" "Open new major version")
fi

set +e

"${cmd[@]}" 3>&1 1>&2 2>&3

exit 0;
