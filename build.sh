#!/bin/bash
set -x

now_path=`pwd`
tagVersion=""

if [ "$#" -ge 1 ];then
	tagVersion=$1
fi
if [ "$tagVersion"x == ""x ];then
	echo "tagVersion is nil"
	exit 0
fi

target_binary=""
if [[ $tagVersion == *"_bs"* ]]
then
    target_binary="bid-server"
elif [[ $tagVersion == *"_ps"* ]]
then
    target_binary="prebid-server"
else
    echo "invalid tag version $tagVersion"
    exit 5
fi


#build image
cd ${now_path}/docker
bash make_compileenv_docker.sh
if [ $? -ne 0 ];then
	echo "make_compileenv_docker.sh failed"
	exit 1
fi
bash make_runenv_docker.sh
if [ $? -ne 0 ];then
	echo "make_runenv_docker.sh failed"
	exit 2
fi

bash generate.sh $tagVersion $target_binary
if [ $? -ne 0 ];then
	echo "generate.sh failed"
	exit 3
fi

#upload to aws s3
if [ ! -d ${now_path}/output ];then
	mkdir -p ${now_path}/output
fi
if [ ! -d ${now_path}/output/bin ];then
	mkdir -p ${now_path}/output/bin
fi

tdir="${now_path}/docker/${tagVersion}"
if [ -d $tdir ];then
	echo 'y' | cp -rf ${now_path}/docker/${tagVersion}/bin/${target_binary} ${now_path}/output/bin
	echo 'y' | cp -rf ${now_path}/docker/${tagVersion}/config ${now_path}/output/
	rm -rf $tdir
else
	echo "dir:${now_path}/docker/${tagVersion} not exist"
fi
exit 0

