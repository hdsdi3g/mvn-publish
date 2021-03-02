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
#    Usage: just run this script from a maven and git repository
#           you must have a valid setup of:
#             - git
#             - mvn
#             - whiptail
#             - bc
#
#    Update: you can use shellcheck for validate this script
#

set -eu

if [ ! -f "pom.xml" ]; then
	echo "Can't found pom.xml in this directory" >&2;
	exit 1;
fi

git fetch -p
git reset --hard
git pull

POM_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout);

RELATIVE_DIR=$(dirname $(realpath "$0"));
NEW_POM_VERSION=$("$RELATIVE_DIR/choose-new-version.bash" "$POM_VERSION");

if [[ "$NEW_POM_VERSION" == ""  ]]; then
	echo "Cancel operation"
	exit 0;
fi

if [[ "$NEW_POM_VERSION" =~ .*"SNAPSHOT".*  ]]; then
	ACTION_LIST=$(whiptail --title "Confirm actions" --checklist \
	"What do you want to do with new $NEW_POM_VERSION?" 0 0 4 \
	"4" "Clean and test" OFF \
	"6" "Install locally" OFF \
	"9" "Create git branch" OFF \
	"5" "Commit new pom.xml" ON \
	"7" "Git push" ON 3>&1 1>&2 2>&3);
else
	ACTION_LIST=$(whiptail --title "Confirm actions" --checklist \
	"What do you want to do with current $NEW_POM_VERSION?" 0 0 4 \
	"4" "Clean and test" OFF \
	"6" "Install locally" OFF \
	"0" "Clean, test and deploy" ON \
	"1a" "Staging release" ON \
	"2" "Commit new pom.xml" ON \
	"3" "Tag" ON \
	"7" "Git push" ON \
	"8" "Git push tags" ON \
	"1b" "Drop release" OFF \
	3>&1 1>&2 2>&3);
fi

if [[ "$ACTION_LIST" == ""  ]]; then
        echo "No selected items, cancel operation"
fi

if [[ $ACTION_LIST =~ "9" ]] ; then
	if [ "$($RELATIVE_DIR/is-gh.bash)" -eq 1 ]; then
		if [ "$(whiptail --yesno "Do you want create a branch based on GitHub issue ?" 0 0 3>&1 1>&2 2>&3 ; echo $?)" -eq 0 ]; then
			NEW_BRANCH_NAME=$($RELATIVE_DIR/gh-select-issue.sh);
			if [[ "$NEW_BRANCH_NAME" == ""  ]]; then
				echo "No branch name, cancel operation"
				exit 1;
			fi
			NEW_BRANCH_NAME="issue$NEW_BRANCH_NAME";
		else
			NEW_BRANCH_NAME=$(whiptail --title "Create git branch" --inputbox "Enter the new branch name:" 0 0 3>&1 1>&2 2>&3);
		fi
	else
		NEW_BRANCH_NAME=$(whiptail --title "Create git branch" --inputbox "Enter the new branch name:" 0 0 3>&1 1>&2 2>&3);
	fi

	ACTUAl_BRANCH=$(git rev-parse --abbrev-ref HEAD);
	BRANCH_REF_NAME=$(whiptail --title "From this git branch reference" --inputbox "Enter the actual branch name:" 0 0 "$ACTUAl_BRANCH" 3>&1 1>&2 2>&3);
	if [[ "$NEW_BRANCH_NAME" == ""  ]]; then
		echo "No branch name, cancel operation"
		exit 1;
	fi
	echo "Create branch $NEW_BRANCH_NAME derived from $BRANCH_REF_NAME";
	git checkout "$BRANCH_REF_NAME"
	git fetch
	git reset --hard "origin/$BRANCH_REF_NAME"
	git checkout -b "$NEW_BRANCH_NAME" "origin/$BRANCH_REF_NAME"
	git push --set-upstream origin "$NEW_BRANCH_NAME"
fi

if [[ "$POM_VERSION" == "$NEW_POM_VERSION"  ]]; then
	echo "Don't change pom version..."
else
	echo "Change the version in pom.xml...";
	mvn -B versions:set -DnewVersion="$NEW_POM_VERSION" -Dorg.slf4j.simpleLogger.defaultLogLevel=WARN
	find . -type f -name pom.xml.versionsBackup -delete
fi

if [[ $ACTION_LIST =~ "4" ]] ; then
	mvn -B clean test
fi
if [[ $ACTION_LIST =~ "0" ]] ; then
	mvn -B clean deploy -DstagingProgressTimeoutMinutes=30
fi
if [[ $ACTION_LIST =~ "6" ]] ; then
	mvn -B clean install
	echo "Install locally $NEW_POM_VERSION"
fi
if [[ $ACTION_LIST =~ "1a" ]] ; then
	mvn -B nexus-staging:release -DstagingProgressTimeoutMinutes=30
fi
if [[ $ACTION_LIST =~ "1b" ]] ; then
	mvn -B nexus-staging:drop -DstagingProgressTimeoutMinutes=30
fi

addPOM () {
	git add pom.xml
	if [ "$(find . -type f -name pom.xml -printf '.' | wc -c)" -gt 1 ]; then
		git add "./**/pom.xml"
	fi
}

addTHIRDPARTY () {
	if [ -f "THIRD-PARTY.txt" ]; then
		git add THIRD-PARTY.txt
	fi
	if [ "$(find . -mindepth 2 -type f -name THIRD-PARTY.txt -printf '.' | wc -c)" -gt 0 ]; then
		git add "./**/THIRD-PARTY.txt"
	fi
}

if [[ $ACTION_LIST =~ "5" ]] ; then
	addPOM
	addTHIRDPARTY
	git commit -m "Open version $NEW_POM_VERSION"
fi
if [[ $ACTION_LIST =~ "2" ]] ; then
	addPOM
	addTHIRDPARTY
	git commit -m "Set version $NEW_POM_VERSION"
fi
if [[ $ACTION_LIST =~ "3" ]] ; then
	git tag "$NEW_POM_VERSION"
fi
if [[ $ACTION_LIST =~ "7" ]] ; then
	git push
fi
if [[ $ACTION_LIST =~ "8" ]] ; then
	git push --tags
fi
