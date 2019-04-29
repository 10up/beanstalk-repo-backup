#!/bin/bash

########
#
# Beanstalk Backup Script
#
# Uses the Beanstalk API to backup all version control repositories
# in an account.
#
# Dependencies
#  * curl
#  * jq
#  * git
#  * subversion
#  * Have SVN and Git setup to download repos without additional authentication
#
#
# Reference: http://api.beanstalkapp.com/
#
# URL: https://github.com/10up/beanstalk-repo-backup
# URL: https://10up.com
#
# Author: Zachary Brown
#
########

# Beanstalk user and token. See http://api.beanstalkapp.com/ for documentation
#username=user
#password=generated-beanstalk-token

# Destination directories for backups
# (PLEASE INCLUDE TRAILING SLASH)
SVNDIR=/tmp/repos/svnbackup/ #Intermediate storage for svn
GITDIR=/tmp/repos/gitbackup/ #Intermediate storage for git
BACKUPDIR=/tmp/repos/repobackup/ #Final destination for compressed backups

[ -d ${BACKUPDIR} ] || mkdir -p ${BACKUPDIR}

REPOS=($(curl -u ${username}:${password} -H "Content-Type: application/json" https://10up.beanstalkapp.com/api/repositories.json | jq '.[].repository.repository_url'))

for R in "${REPOS[@]}"
do
        NQ=$(echo "$R" | tr -d '"')
        if (echo "$NQ" | grep 10up.svn)
        then
                [ -d ${SVNDIR} ] || mkdir -p ${SVNDIR}
                cd ${SVNDIR}
                DUMPFILE=$(echo "${NQ}" | cut -d'/' -f 4)
                svnrdump dump -r0:HEAD ${NQ} > ${DUMPFILE}.svn.dmp
        elif (echo "$NQ" | grep git)
        then
                [ -d ${GITDIR} ] || mkdir -p ${GITDIR}
                cd ${GITDIR}
                # Backup the Git repo 2 ways for future convenience
                git clone ${NQ}
                git clone --mirror ${NQ}
        fi
done

# Compress Git backups
if [ -d ${GITDIR} ]
then
        cd ${GITDIR}
        ls > /tmp/gitfiles.tmp
        while read line
        do
                echo ${line}
                tar -czf ${BACKUPDIR}${line}.tar.gz ${line}
        done < /tmp/gitfiles.tmp
fi

# Compress SVN backups
if [ -d ${SVNDIR} ]
then
        cd ${SVNDIR}
        gzip -9 *
        mv ${SVNDIR}*.gz ${BACKUPDIR}
fi

# Cleanup
rm -rf ${GITDIR}
rm -rf ${SVNDIR}