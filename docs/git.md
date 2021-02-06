# GIT useful steps

## Clone

git clone [url]

## See all remote branches and upstream

git branch -a  
git branch -vv

## Create new branch in local

git checkout -b branchname

## Go to remote branch

git checkout --track origin/branchname

## Set upstream

git checkout branchname  
git push -u origin/branchname for branch that alr exists  
git push -u origin branchname to push new branch to remote

## Cloning a single branch

git clone --branch [branchname] --single-branch [remote-repo-url]

## Removing git from directory

rm -rf .git

## Removing latest commit < not yet pushed >

git reset HEAD^
