#!/bin/bash

check(){
  if [ "$1"x == "--microk8s"x ]
  then
    logs=`microk8s kubectl get pod --all-namespaces|tail -n +2|grep -v Running|while read line
    do
     declare -a arr=( $line )
     microk8s kubectl describe pod ${arr[1]} --namespace=${arr[0]}
    done|grep -i "image"|sed -nr 's/.*(failed to pull|Back-off pulling) image \"([^\"]+)\".*/\2/p'|uniq`
    echo ${logs}
  fi
}

pull(){
  image=$1
  imageName=${image/#k8s\.gcr\.io\//}
  if [ "$image"x == "$imageName"x ]
  then
    imageName=${image/#gcr\.io\/google_containers\//}
  fi
  echo Pull $imageName ...
  if [ "$image"x == "$imageName"x ]
  then
    echo Pull $imageName ...
    docker pull $image
    exit 0
  fi
  hubimage=${imageName//\//\-}

  if [ -n ”$hubimage“ ]
  then
    echo Pull $imageName ...
    docker pull opsdockerimage/$hubimage
    docker tag opsdockerimage/$hubimage $1
    docker rmi opsdockerimage/$hubimage
    if [ "$2"x == "--microk8s"x ]
    then
      saveImage=${1#:}
      docker save $saveImage > ~/.docker_image.tmp.tar
      microk8s ctr image import ~/.docker_image.tmp.tar
      rm ~/.docker_image.tmp.tar
    fi
  fi
}



if [ "$1"x == "check"x ]
then
  check $2
  exit 0
fi


if [ "$1"x == "pull"x -a $# -ge 2 ]
then
  pull $2 $3
  exit 0
fi


echo
echo "Usage:  pullk8s COMMAND [NAME[:TAG|@DIGEST]] [OPTIONS]"
echo
echo "Pull gcr.io's image for hub.docker.com"
echo
echo "Commands:"
echo "  check    Check gcr.io's fail pull images."
echo "  pull     Pull an image or a repository"
echo
echo "Options:"
echo "  --microk8s  If use MicroK8s release."
echo
echo "Examples:"
echo "  pullk8s pull k8s.gcr.io/pause:3.6 --microk8s"
echo "  pullk8s pull gcr.io/google_containers/etcd:2.0.12"
echo "  pullk8s check --microk8"
exit 1