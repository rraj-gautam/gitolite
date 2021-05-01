#!/bin/bash

#dir=/home/git
dir=/home/rraj/Documents/projects
git_dir=$dir/gitolite-admin
conf=conf/gitolite.conf
keys=keydir
cd $git_dir;
alias git_make='git add . && git commit -m "${message}" && git push'
git_url=git@192.168.100.20:81
http_url=http://192.168.100.20:81
public_http_url=http://192.168.100.20:82

#function clone(){
#       cd $dir;
#       git clone $git_url:/gitolite-admin
#}

function pull(){
        git pull;
}

function createUser(){
        user=$1
        passwordHash=$2
        echo "$user:$passwordHash" >> ${dir}/.passwd
}

function deleteUser(){
        user=$1
        sed -i "/$user/d" ${dir}/.passwd
        rm -f ${keys}/$user.pub
        git_make
}

function UpdatePassword(){
        user=$1
        passwordHash=$2
        sed -i "s/$user:.*/$user:$password/g" ${dir}/.passwd
}

function addUserSsh(){
        user=$1
        sshKey=$2
        echo $sshKey > ${keys}/$user.pub
        git_make
}

function updateUserSsh(){
        user=$1
        sshKey=$2
        addUserSsh $user $sshKey
}

function createRepo(){
        repo=$1
        repoHash=$2 
        echo "repo $repo #{$repoHash}"  >> ${conf}                                                       
        git_make
}

function createUserRepo(){
        repoUser=$1
        repo=$2
        echo "" >> ${conf}
        echo "repo $repoUser/$repo" >> ${conf}                                                 
        git_make 
        accessType=RW+
        repoAccessHash=$3
        addRepoAccess $repoUser $repo $user $accessType $repoAccessHash             
}

function addRepoAccess(){
        repoUser=$1
        repo=$2
        user=$3
        repoAccessHash=$4
        sed -i "/^repo $repoUser\/$repo/a $accessType = $user  #{$repoAccessHash}" ${conf}
        git_make
}

function removeRepoAccess(){
        repoAccessHash=$1
        sed -i "/#${repoAccessHash}/d" ${conf}
        git_make
}

function deleteRepo(){
        repoHash=$1
        sed -i "/#${repoHash}/,/repo/{//p;d;};" ${conf}
        sed -i "/#{repoHash}/d" ${conf}
}

#function createGroup(){}

#case $1 in
#       createrepo) "$@"; exit;;
#       createUserRepo) "$@"; exit;;
#esac

