#!/bin/bash
if [[ ! -f output.sh ]]; then
    curl https://gist.githubusercontent.com/yremmet/1a77ac70b1a24cb901e28233219c5663/raw/b93d4a52be6e5572998ef1deb1f172599a68f919/output.sh -o output.sh
fi
. output.sh
. state.sh

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

function deployments(){
    header Deployments
    echo::green "Listing Deployments"
    for deployment in $(find . -name "docker-compose.yaml" | cut -d'/' -f2 ); do
        if [[ $deployment != "legacy" ]]; then
            echo::blue "- $deployment"
        fi
    done
}

function manifest(){
    header "Manifest Info"
    echo::blue "Manifest Source"
    echo::blue "Remote:  $(git remote get-url origin)"
    if [[ $(git status --porcelain | wc -l) -gt 0 ]]; then
        echo::red "Uncommited changes:"
        for x in $(git status --porcelain | awk '{print $2}' ); do
            echo::red " - $x"
        done
    else
        ok  "Repo is clean"
    fi
}

function check(){
    [[ $1 == "" ]] && fail "Usage idt $command \$deployment_name"
    [[ -d $1 ]] || fail "Deployment $1 doesn't exists"
    [[ -f $1/docker-compose.yaml ]] || fail "Deployment $1/docker-compose.yaml doesn't exists"
}

function images(){
    check $@
    deployment=$1
    header "Images For deployment $deployment"
    for image in $(cat $deployment/docker-compose.yaml | grep image | cut -d':'  -f2); do
        details=$(docker images  | grep $image | grep -v none | head -n1)
        info "$image\t$(echo $details |  awk '{print $2}') \t$(echo $details |  awk '{print $3}')"
    done
}


function waitForUp(){
    check $@
    deployment=$1
    pushd $deployment
        services=$(docker-compose ps | awk 'NR > 2 {print $0}' | wc -l)
        for i in {1..10}; do
            if [[ $(docker-compose ps | awk 'NR > 2 {print $0}' | grep Up | wc -l) == $services ]]; then
                echo ""
                ok "$deployment is fully up"
                return
            fi
            printf "."
       done
    popd
}

function update(){
    state::sync
    state::update $1
    check $@
    deployment=$1
    header "Updating deployment $deployment"
    pushd $deployment
        docker-compose pull
        docker-compose up -d
    popd
    sleep 20
    popd
    waitForUp $deployment
    state::update $1
    state::sync
}

function stop(){
    check $@
    header "Stopping $1"
    pushd 
        docker-compose down
    popd
}

function start(){
    check $@
    header "Starting $1"
    pushd 
        docker-compose up
    popd
    waitForUp $1
}

command=$1
shift
case $command in
    deployments|d)
        deployments $@;;
    info|i)
        info $@;;
    images|img)
        images $@;;
    manifest)
        manifest $@;;
    update|u)
        update $@;;
    start)
        start $@;;
    stop)
        stop $@;;
    ## META
    init_state)
        state::init;;

    ## Default
    *)
        help;;

esac