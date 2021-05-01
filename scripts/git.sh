#!/bin/bash

#dir=/home/git
admin=rraj
dir=/home/rraj/Documents/projects
git_dir=${dir}/gitolite-admin
conf=${git_dir}/conf/gitolite.conf
keys_dir=${git_dir}/keydir
#cd $git_dir;
shopt -s expand_aliases
alias git_make="git -C $git_dir add .  && git -C $git_dir commit -m'{$message}' && git -C $git_dir push"
alias git_build="git -C $readmeDir add .  && git -C $readmeDir commit -m'{$message}' && git -C $readmeDir push"
git_url=git@192.168.100.20
http_url=http://192.168.100.20:81
public_http_url=http://192.168.100.20:82

echo "running script"
#function clone(){
#       cd $dir;
#       git clone $git_url:/gitolite-admin
#}

function pull(){
        git pull;
}

function createUser(){
        echo "running createUser"
        user=$1
        passwordHash=$2
        pass=$(printf '%q\n' $2)
        echo $pass
        sed -i "s/USER:.*/USER: $user/g" password-vars.yaml
        sed -i 's/PASS:.*/PASS: '"$pass"' /g' password-vars.yaml
        #echo "$user:$passwordHash" >> ${dir}/.passwd
        /usr/bin/ansible-playbook -i hosts_git.yaml  htpassword.yaml --tags "create"
}

function deleteUser(){
        user=$1
        #sed -i "/$user/d" ${dir}/.passwd
        sed -i "s/USER:.*/USER: $user/g" password-vars.yaml
        #echo "$user: $passwordHash" >> ${dir}/.passwd
        /usr/bin/ansible-playbook -i hosts_git.yaml  htpassword.yaml --tags "delete"  
        if [ -e ${keys_dir}/${user} ] 
        then   
        rm -f ${keys_dir}/${user}
        message=$(echo "deleted user ${user}")
        git_make
        fi
}

function updatePassword(){
        echo "running update password"
        user1=$1
        passwordHash1=$2
        #sed -i "s/$user:.*/$user:$password/g" ${dir}/.passwd
        sed -i "s/USER:.*/USER: $user1/g" password-vars.yaml
        sed -i 's/PASS:.*/PASS: '"$passwordHash1"' /g' password-vars.yaml
        #echo "$user:$passwordHash" >> ${dir}/.passwd
        /usr/bin/ansible-playbook -i hosts_git.yaml  htpassword.yaml --tags "update"        
}

function addUserSsh(){
        user=$1
        sshKey=$2
        keyHash=$3
        #folder=${keys_dir}/${user}
        # if [ ! -d "$folder" ]; then
        #         mkdir -p ${folder}/key1;
        #         echo $sshKey > ${folder}/key1/${user}.pub    
        if [[ "$keyHash" == "key1" ]]; then   
                mkdir -p ${keys_dir}/${user}/${keyHash};
                echo $sshKey > ${keys_dir}/${user}/${keyHash}/${user}.pub                   
        else
                mkdir -p ${keys_dir}/${user}/${keyHash};
                echo $sshKey > ${keys_dir}/${user}/${keyHash}/${user}.pub 
        fi
        message=$(echo "added sshKey of user: ${user}")
        git_make
}

function updateUserSsh(){
        user=$1
        sshKey=$2
        keyHash=$3
        #addUserSsh $user $sshKey $keyHash
        echo $sshKey > ${keys_dir}/${user}/${keyHash}/${user}.pub 
        message=$(echo "added sshKey of user: ${user}")
        git_make        

}

function deleteUserSsh(){
        user=$1
        keyHash=$2
        rm -rf ${keys_dir}/${user}/${keyHash}
}

function createRepo(){
        repo=$1
        repoHash=$2 
        echo "repo $repo #{$repoHash}"  >> ${conf}
        message=$(echo "created repo ${repo}")                                                       
        git_make
}

function createUserRepo(){
        repoUser=$1
        repo=$2
        repoHash=$3
        echo "" >> ${conf}
        echo "repo $repoUser/$repo  #${repoHash}"  >> ${conf}    
        #message=$(echo "created repo ${repo}")                                              
        #git_make 
        accessType=RW+
        httpAccessHash=$4   #default http access hash
        repoAccessHash=$5   #default RW access hash for user 
        sed -i "/#$repoHash\b/a R = daemon  #${httpAccessHash}" ${conf}
        #sed -i "/^repo $repoUser\/$repo/a R = daemon  #${httpAccessHash}" ${conf}
        addRepoAccess $repoHash $repo $user $accessType $repoAccessHash             
}

function addRepoAccess(){
        repoHash=$1
        repo=$2
        user=$3
        accessType=$4
        repoAccessHash=$5
        #sed -i "/$repoHash/a $accessType = $user  #${repoAccessHash}" ${conf}
        sed -i "/#$repoHash\b/a $accessType = $user  #$repoAccessHash" ${conf}
        message=$(echo "provided repo access to user $user on repo $repo") 
        git_make
}

function removeRepoAccess(){
        repoAccessHash=$1
        sed -i "/#${repoAccessHash}/d" ${conf}
        message=$(echo "removed repo access") 
        git_make
        
}

function deleteRepo(){
        repoHash=$1
        repo=$2
        sed -i "/#${repoHash}/,/repo/{//p;d;};" ${conf}
        sed -i "/#${repoHash}/d" ${conf}
        message=$(echo "deleted repo ${repo}") 
        git_make        
}

function makeRepoPublic(){
       repoHash=$1
       repo=$2
       httpPublicAccessHash=$3
       user=$admin
       accessType=RW+
       repoAccessHash=$4 #access for admin to pull the repo
       sed -i "/#$repoHash\b/a option hook.post-update = make-public  #${httpPublicAccessHash}" ${conf} 
       addRepoAccess $repoHash $repo $user $accessType $repoAccessHash
       #message=$(echo "made repo ${repo} publicly accessible") 
        #git_make     
        addReadme $repo
}

function addReadme(){
        repo=$1
        git clone ${git_url}:${repo}
        readmeDir=$(ls -lthr | tail -n1|awk '{print $9}')
        touch $readmeDir/Readme.md
        message=$(echo "added readme file") 
        git_build
        rm -rf $readmeDir
}
#function createGroup(){}

#case $1 in
#       createrepo) "$@"; exit;;
#       createUserRepo) "$@"; exit;;
#esac