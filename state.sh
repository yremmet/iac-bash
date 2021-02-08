state::init(){
  if [[ ! -d state ]]; then
    git clone $(git remote get-url origin) -b state state
  fi
  for deployment in $(find . -name "docker-compose.yaml" | cut -d'/' -f2 ); do
        state::update $deployment
  done
  state::sync
}

state::pull(){
  pushd state
    git pull
  popd
}

state::push(){
  pushd state
    git push
  popd
}

state::sync(){
  state::pull
  state::push
}


state::update() {
  local deployment=$1
  pushd $deployment
    echo::blue "Updating State of $deployment"
    tmp_dir=$(mktemp -d)

    for job in $(docker-compose ps | awk 'NR > 2 {print $1}'); do
      docker inspect $job | jq ' .[0] | { "container": .Name , "image": .Image, "id": .Id,  "ports": .NetworkSettings.Ports} ' > $tmp_dir/$job.json
      docker inspect $job  | jq  '.[0].NetworkSettings.Networks | to_entries[] |  {(.key): { "ipa": .value.IPAddress, "gateway":  .value.Gateway }}' | jq -s '{"networks" : . }' > $tmp_dir/$job-nw.json
      jq -s '.[0] * .[1]' $(ls $tmp_dir/$job*.json) > $tmp_dir/$job-complete.json
    done
    ls $tmp_dir/*-complete.json
    if [[ $? == 2 ]]; then
       popd
       return 2
    fi
    jq --arg name "${PWD##*/}" -s '{($name): .}' $(ls $tmp_dir/*-complete.json) > $tmp_dir/state.json

  popd

  pushd state
    jq -s '.[0] * .[1]' state.json $tmp_dir/state.json > state.new.json
    mv state.new.json state.json
    git add state.json
    git commit -m "Updated state for $deployment"
  popd
}