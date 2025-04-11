#!/bin/bash

# From strikeoncmputrz/LLM_Scripts
# License: Apache-2.0, can be found in the same folder as this script

# Global Vars
ollama_url=http://localhost
port="11434"
blobs=()
model_name_paths=()


#Parse arguments
while [ "$#" -gt 0 ]; do
  case $1 in
    -h|--help)
      echo 
      echo " Identifies Ollama models running on this operating system by parsing running processes."
      echo 
      echo " Usage: $0 [options]"   
      echo
      echo " Options:"
      echo "  -j, --json_output        Prints result as a json object. Other output disabled. (Default: false)"      
      echo "  -p, --port [port number] Specify Ollama Server port (Default: 11434)"
      echo "  -u, --ollama_url [url]   Specify Ollama Server URL (Default: http://localhost)"
      echo
      echo " Dependencies: jq"
      exit 0
      ;;
    -j|--json_output)
      json_out=1
      shift 1
      ;;
    -u|--ollama_url)
      ollama_url=$2
      shift 2
      ;;
    -p|--port)
      port=$2
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

compare_running_models_and_modelfiles() { 
    json_match=()
    json_output=()
    local matching_models=()
    OLDIFS=$IFS
    for ((i=0; i<${#model_name_paths[@]}; i++)); do  # Iterate over the array of modelname,blob-path
        for blob in "${blobs[@]}"; do
            IFS=',', read -ra fields <<< "${model_name_paths[i]}"    # Split the string into parts
            if [ "${fields[1]}" == "$blob" ]; then  # Check if current 'field' matches a blob
                matching_models+=( '{ "model": "'"${fields[0]}"'", "path": "'"${fields[1]}"'"}') # Add to list of matching models
            fi
        done
    done
    
    if [ -z "$json_out" ]; then
        echo -e "\nModel Found: \n $(echo ${matching_models[*]} | jq '.' | sed s/[{}]//g) \n"        
    else
        local json_match="${matching_models[*]}"
        json_output=$(echo $json_match | jq -c -s .)
        echo "$json_output"
    fi
    IFS=$OLDIFS
}

get_running_model_paths() {
    blobs=$(ps aux | grep -- '--model' | grep -v grep | grep -Po '(?<=--model\s).*' | cut -d ' ' -f1)
    if [ -z "$blobs" ]; then
        echo -e "\n\n Warning: No running Ollama models detected!\n"
        exit 0
    fi
}

parse_modelfiles() {
    if [ -z "$json_out" ]; then
        echo -e "\nConnecting to $ollama_url:$port\n"
        if [ -z "$(curl -s $ollama_url:$port)" ]; then
           echo -e "Could not connect to Ollama. Check the ollama_url parameter and that the server is running\n"
           exit 1
        fi
        curl -s "$ollama_url:$port"
    fi
    local models=( $(curl -s "$ollama_url:$port/api/tags" | jq -r '.models[].name') )
    for model in "${models[@]}"; do
        local modelfile=$(curl -s "$ollama_url:$port/api/show" -d '{ "name": "'"$model"'", "modelfile": true }' | jq   -r '.modelfile')
        model_name_paths+=($model,$(echo "$modelfile" | awk '/^FROM/{print $2}'))
    done
}

parse_modelfiles
get_running_model_paths
compare_running_models_and_modelfiles
