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
#    Usage: select-run-test.bash
#
set -eu

git pull

if (whiptail --title "Install globally all projects" --yesno "Do you want to do skip the global install for alls current projects?" 0 0); then
    echo "";
else
    mvn clean install -Dgpg.skip=false -DskipTests=true -Dorg.slf4j.simpleLogger.defaultLogLevel=WARN -Dmaven.javadoc.skip=true
fi

LAST_RUN_TEST_FILE="last-run-mvn-tests";
LAST_RUN_TEST=$(find . -type f -name "$LAST_RUN_TEST_FILE" | head -1);

resolve_project_name () {
    local DIRNAME="$1";
    local PROJECT_NAME_FILE="$DIRNAME/target/projectname.txt";
    if ! [ -f "$PROJECT_NAME_FILE" ]; then
        mvn -f "$i" help:evaluate -Dexpression=project.name -q -DforceStdout > "$PROJECT_NAME_FILE"
    fi
    cat "$PROJECT_NAME_FILE";
}

if [ -f "$LAST_RUN_TEST" ]; then
    DIRNAME=$(dirname "$(dirname "$LAST_RUN_TEST")");
    PROJECT_NAME=$(resolve_project_name $DIRNAME);
    #mvn test -pl "$LAST_RUN_TEST"
    echo "$DIRNAME $PROJECT_NAME";
    if (whiptail --title "Confirm the project to run tests" --yesno "Do you want to run tests for $PROJECT_NAME project?" 0 0); then
        mvn test -pl "$DIRNAME"
        exit 0;
    else
        rm -f "$LAST_RUN_TEST";
    fi
fi

cmdList=(whiptail --title "Select the project to run tests:" --menu "What to run?" 0 0 0);

shopt -s globstar
for i in **/pom.xml; do
    DIRNAME=$(dirname $i);
    if ! [ -f "$DIRNAME/target/maven-status/maven-compiler-plugin/testCompile/default-testCompile/createdFiles.lst" ]; then
        continue;
    fi
    PROJECT_NAME=$(resolve_project_name $DIRNAME);
    cmdList+=("$DIRNAME" " $PROJECT_NAME");
done

SELECTED_PROJECT=$("${cmdList[@]}" 3>&1 1>&2 2>&3);
set +e

echo "1" > "$SELECTED_PROJECT/target/$LAST_RUN_TEST_FILE";

echo "$SELECTED_PROJECT";

mvn test -pl "$SELECTED_PROJECT"

exit 0;
