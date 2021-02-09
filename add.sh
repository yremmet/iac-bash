#!/bin/bash
composeFile="$pathdir/tmp.yaml"
function add(){


    echo::blue "New Deployment Name:"
    read name
    [[ -d $name ]] && fail "Deployment $name already exists"
    echo::blue "Source Compose Path:"
    read path
    if [[ $path == *"http"* ]]; then
        curl $path -Lo $composeFile
    else
        cp $path $composeFile
    fi
    docker-compose -f $composeFile config  > /dev/null
    [[ $? != 0 ]] && fail "No Valid Compose File" || ok "Valid Compose File found"

    for service in $(docker-compose -f $composeFile config --services); do
        echo::blue "Adding Endpoint for $service [y/N]"
        read sw
        if [[ $sw == "y" ]]; then
            echo "adding labels traefik"
            echo "adding labels traefik"
        fi 
        echo "adding labels owner"
        echo "removing ports"
    done
    echo::blue "Do you want to edit the configuration? [y/N]"
    read sw
    if [[ $sw == "y" ]]; then
        vim $composeFile 
    fi 
    mkdir $name
    cp $composeFile $name/docker-compose.yaml


    
}