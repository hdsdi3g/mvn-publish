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
#             - gh
#
#    Update: you can use shellcheck for validate this script
#

set -eu
CHANGELOGFILE="CHANGELOG.md";
PRODLIB_VERSION_FILE="env-version/src/main/resources/prodlib-version.txt";
JAVA_HOME=$(dirname "$(dirname "$(realpath "$(command -v java)")")");
export JAVA_HOME=$JAVA_HOME;

if [ ! -f "pom.xml" ]; then
	echo "Can't found pom.xml in this directory" >&2;
	exit 1;
fi

git fetch -p
git reset
git pull

POM_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout);
RELATIVE_DIR=$(dirname "$(realpath "$0")");

IS_MAIN_BRANCH="0";
ACTUAl_BRANCH=$(git rev-parse --abbrev-ref HEAD);
if [[ "$ACTUAl_BRANCH" == "main" || "$ACTUAl_BRANCH" == "master" ]]; then
	IS_MAIN_BRANCH="1";
fi
BASE_BRANCH=$("$RELATIVE_DIR/git-get-base-branch");
NEW_POM_VERSION=$("$RELATIVE_DIR/choose-new-version.bash" "$POM_VERSION" "$IS_MAIN_BRANCH" "$ACTUAl_BRANCH");

if [[ "$NEW_POM_VERSION" == "" ]]; then
	echo "Cancel operation"
	exit 0;
fi

if [[ "$NEW_POM_VERSION" == "PR" ]]; then
	"$RELATIVE_DIR/gh-create-pr.sh"
	exit 0;
fi

if [[ "$NEW_POM_VERSION" =~ .*"SNAPSHOT".*  ]]; then
	cmd=(whiptail --title "Confirm actions" --checklist "What do you want to do with new $NEW_POM_VERSION?" 0 0 4);
	cmd+=("A04" "Clean and test" OFF);
	cmd+=("A06" "Install locally" OFF);
	cmd+=("A09" "Create git branch" OFF);
	cmd+=("A05" "Commit new pom.xml (and auto-generated files)" ON);
	cmd+=("A07" "Git push" ON);
	ACTION_LIST=$("${cmd[@]}" 3>&1 1>&2 2>&3);
else
	cmd=(whiptail --title "Confirm actions" --checklist "What do you want to do with current $NEW_POM_VERSION?" 0 0 4);
	cmd+=("A04" "Clean and test" OFF);
	cmd+=("A06" "Install locally" OFF);
	if [[ "$BASE_BRANCH" != "" && "$ACTUAl_BRANCH" != "master" && "$ACTUAl_BRANCH" != "main" ]]; then
		cmd+=("A12" "Verify current PR status" ON);
	fi
	cmd+=("A1C" "Clean, deploy" ON);
	cmd+=("A1D" "Clean, test and deploy" OFF);
	cmd+=("A1A" "Staging release" OFF);
	if [ -f "$CHANGELOGFILE" ]; then
		cmd+=("A14" "Edit $CHANGELOGFILE" ON);
	fi
	cmd+=("A02" "Commit new pom.xml (and auto-generated files)" ON);
	cmd+=("A03" "Git tag to $NEW_POM_VERSION" ON);
	cmd+=("A07" "Git push $ACTUAl_BRANCH" ON);
	cmd+=("A08" "Git push tag" ON);
	if [[ "$BASE_BRANCH" != "" && "$ACTUAl_BRANCH" != "master" && "$ACTUAl_BRANCH" != "main"  ]]; then
		cmd+=("A10" "Git merge $ACTUAl_BRANCH to $BASE_BRANCH" ON);
		cmd+=("A11" "Git delete local $ACTUAl_BRANCH" ON);
		cmd+=("A13" "Git (final) push to $BASE_BRANCH" ON);
	fi
	cmd+=("A1B" "Drop release" OFF);
	if [ -x "$(command -v make-springboot-deb)" ]; then
		cmd+=("A15" "Make deb package" OFF);
		if [ -x "$(command -v manage-internal-deb-repo)" ]; then
			cmd+=("A16" "Publish (localy) created deb package" OFF);
		fi
	fi
	ACTION_LIST=$("${cmd[@]}" 3>&1 1>&2 2>&3);
fi

if [[ "$ACTION_LIST" == ""  ]]; then
    echo "No selected items, cancel operation"
	exit 0;
fi

if [[ "$ACTION_LIST" =~ "A14" ]] ; then
	edit-changelog;
fi

if [[ "$ACTION_LIST" =~ "A04" ]] ; then
	mvn clean test -Djacoco.skip=true -Dlicense.skipAddThirdParty=true -Dagent=false
fi

if [[ "$ACTION_LIST" =~ "A09" ]] ; then
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

if [[ "$ACTION_LIST" =~ "A12" ]] ; then
	gh pr status
	gh pr checks
fi

if [[ "$ACTION_LIST" =~ "A14" ]] ; then
	git add "$CHANGELOGFILE";
fi

if [[ "$POM_VERSION" == "$NEW_POM_VERSION"  ]]; then
	echo "Don't change pom version..."
else
	echo "Change the version in pom.xml...";
	mvn versions:set -DnewVersion="$NEW_POM_VERSION" -Dorg.slf4j.simpleLogger.defaultLogLevel=WARN
	find . -type f -name pom.xml.versionsBackup -delete
	write-version-file-for-prodlib "$PRODLIB_VERSION_FILE" "$NEW_POM_VERSION"
fi

if [[ $ACTION_LIST =~ "A1C" ]] ; then
	mvn clean deploy -DstagingProgressTimeoutMinutes=30 -Dgpg.skip=false -DskipTests=true -Djacoco.skip=true -Dmaven.test.skip
fi
if [[ $ACTION_LIST =~ "A1D" ]] ; then
        mvn clean deploy -DstagingProgressTimeoutMinutes=30 -Dgpg.skip=false
fi
if [[ $ACTION_LIST =~ "A06" ]] ; then
	mvn clean install -Dgpg.skip=false -DskipTests=true
	echo "Install locally $NEW_POM_VERSION"
fi
if [[ $ACTION_LIST =~ "A1A" ]] ; then
	mvn nexus-staging:release -DstagingProgressTimeoutMinutes=30 -Dgpg.skip=false
fi
if [[ $ACTION_LIST =~ "A1B" ]] ; then
	mvn nexus-staging:drop -DstagingProgressTimeoutMinutes=30 -Dgpg.skip=false
fi

addPOM () {
	git add pom.xml
	if [ "$(find . -type f -name pom.xml -printf '.' | wc -c)" -gt 1 ]; then
		git add "./**/pom.xml"
	fi
	if [ -f "$PRODLIB_VERSION_FILE" ]; then
		git add "$PRODLIB_VERSION_FILE"
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

addDocsReadme () {
	if [ -d "docs" ]; then
		git add docs
	fi
	if [ -f "README.md" ]; then
		git add README.md
	fi
}

if [[ $ACTION_LIST =~ "A05" ]] ; then
	addPOM
	addTHIRDPARTY
	addDocsReadme
	git commit -m "Open version $NEW_POM_VERSION"
fi
if [[ $ACTION_LIST =~ "A02" ]] ; then
	addPOM
	addTHIRDPARTY
	addDocsReadme
	git commit -m "Set version $NEW_POM_VERSION"
fi
if [[ $ACTION_LIST =~ "A03" ]] ; then
	git tag "$NEW_POM_VERSION"
fi
if [[ $ACTION_LIST =~ "A07" ]] ; then
	git push
fi
if [[ $ACTION_LIST =~ "A08" ]] ; then
	git push --tags
fi

if [[ $IS_MAIN_BRANCH == "0" ]] ; then
	if [[ $ACTION_LIST =~ "A10" ]] ; then
		# Git merge to base branch
		git co "$BASE_BRANCH"
		git merge "$ACTUAl_BRANCH"
		echo "Merge to local $BASE_BRANCH is done. You can now push to distant $BASE_BRANCH and/or rebase before."
		if [[ $ACTION_LIST =~ "A11" ]] ; then
			# Git delete current branch
			"$RELATIVE_DIR/git-delete-local-branch" "$ACTUAl_BRANCH"
		fi
		if [[ $ACTION_LIST =~ "A13" ]] ; then
			# Git push to base branch
			git push
		fi
	else
		if [[ $ACTION_LIST =~ "A11" ]] ; then
			echo "Can't delete a non-merged branch ($ACTUAl_BRANCH).";
		fi
		if [[ $ACTION_LIST =~ "A13" ]] ; then
			echo "Nothing to push";
		fi
	fi
else
	if [[ $ACTION_LIST =~ "A10" ]] ; then
		echo "Can't merge current branch: you're in a current base branch"
	fi
	if [[ $ACTION_LIST =~ "A11" ]] ; then
		echo "Can't delete current branch: you're in a current base branch"
	fi
	if [[ $ACTION_LIST =~ "A13" ]] ; then
		echo "Can't push to final branch: you're in a current base branch"
	fi
fi

if [[ $ACTION_LIST =~ "A15" ]] ; then
	make-springboot-deb .
fi

if [[ $ACTION_LIST =~ "A16" ]] ; then
	LAST_CREATED_DEB=$(find . -maxdepth 1 -type f -name "*.deb" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d " " -f 2);
	if [ ! -f "$LAST_CREATED_DEB" ]; then
		echo "Can't found last created deb file here."
		exit 1;
	fi
	manage-internal-deb-repo "$LAST_CREATED_DEB";
fi
