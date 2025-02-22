#!/usr/bin/env bash
set -euo pipefail

## Defaults
keepGensDef=30; keepDaysDef=30
keepGens=$keepGensDef; keepDays=$keepDaysDef

## Usage
usage () {
    printf "Usage:\n\t ./trim-generations.sh <keep-gernerations> <keep-days> <profile> \n\n
(defaults are: Keep-Gens=$keepGensDef Keep-Days=$keepDaysDef Profile=user)\n\n"
    printf "If you enter any parameters, you must enter all three, or none to use defaults.\n"
    printf "Example:\n\t trim-generations.sh 15 10 home-manager\n"
    printf "  this will work on the home-manager profile and keep all generations from the\n"
    printf "last 10 days, and keep at least 15 generations no matter how old.\n"
    printf "\nProfiles available are:\tuser, home-manager, channels, system (root)\n"
    printf "\n-h or --help prints this help text."
}

if [ $# -eq 1 ]; then      # if help requested
    if [ $1 = "-h" ]; then
         usage
         exit 1;
    fi
    if [ $1 = "--help" ]; then
         usage
         exit 2;
    fi
    printf "Dont recognise your option exiting..\n\n"
    usage
    exit 3;

    elif [ $# -eq 0 ]; then            # print the defaults
        printf "The current defaults are:\n Keep-Gens=$keepGensDef Keep-Days=$keepDaysDef \n\n"
        read -p "Keep these defaults? (y/n):" answer

        case "$answer" in
        [yY1] )
                printf "Using defaults..\n"
            ;;
        [nN0] ) printf "ok, doing nothing, exiting..\n"
            exit 6;
            ;;
        *     ) printf "%b" "Doing nothing, exiting.."
            exit 7;
            ;;
        esac
fi

## Handle parameters (and change if root)
if [[ $EUID -ne 0 ]]; then              # if not root
    profile=$(readlink /home/$USER/.nix-profile)
else
    if [ -d /nix/var/nix/profiles/system ]; then   # maybe this or the other
        profile="/nix/var/nix/profiles/system"
    elif [ -d /nix/var/nix/profiles/default ]; then
        profile="/nix/var/nix/profiles/default"
    else
        echo "Cant find profile for root. Exiting"
        exit 8
    fi
fi
if (( $# < 1 )); then
    printf "Keeping default: $keepGensDef generations OR $keepDaysDef days, whichever is more\n"
elif [[ $# -le 2 ]]; then
    printf "\nError: Not enough arguments.\n\n" >&2
    usage
    exit 1
elif (( $# > 4)); then
    printf "\nError: Too many arguments.\n\n" >&2
    usage
    exit 2
else
    if [ $1 -lt 1 ]; then
        printf "using Gen numbers less than 1 not recommended. Setting to min=1\n"
        read -p "is that ok? (y/n): " asnwer
        #printf "$asnwer"
        case "$asnwer" in
        [yY1] )
            printf "ok, continuing..\n"
            ;;
        [nN0] )
            printf "ok, doing nothing, exiting..\n"
            exit 6;
            ;;
        *     )
            printf "%b" "Doing nothing, exiting.."
            exit 7;
            ;;
        esac
    fi
    if [ $2 -lt 0 ]; then
        printf "using negative days number not recommended. Setting to min=0\n"
        read -p "is that ok? (y/n): " asnwer

        case "$asnwer" in
        [yY1] )
            printf "ok, continuing..\n"
            ;;
        [nN0] )
            printf "ok, doing nothing, exiting..\n"
            exit 6;
            ;;
        *     )
            printf "%b" "Doing nothing, exiting.."
            exit 7;
            ;;
        esac
    fi
    keepGens=$1; keepDays=$2;
    (( keepGens < 1 )) && keepGens=1
    (( keepDays < 0 )) && keepDays=0
    if [[ $EUID -ne 0 ]]; then
        if [[ $3 == "user" ]] || [[ $3 == "default" ]]; then
            profile=$(readlink /home/$USER/.nix-profile)
        elif [[ $3 == "home-manager" ]]; then
            # home-manager defaults to $XDG_STATE_HOME; otherwise, use
            # `home-manager generations` and `nix-store --query --roots
            # /nix/store/...` to figure out what reference is keeping the old
            # generations alive.
            profile="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager"
        elif [[ $3 == "channels" ]]; then
            profile="/nix/var/nix/profiles/per-user/$USER/channels"
        else
            printf "\nError: Do not understand your third argument. Should be one of: (user / home-manager/ channels)\n\n"
            usage
            exit 3
        fi
    else
        if [[ $3 == "system" ]]; then
            profile="/nix/var/nix/profiles/system"
        elif [[ $3 == "user" ]] || [[ $3 == "default" ]]; then
            profile="/nix/var/nix/profiles/default"
        else
            printf "\nError: Do not understand your third argument. Should be one of: (user / system)\n\n"
            usage
            exit 3
        fi
    fi
    printf "OK! \t Keep Gens = $keepGens \t Keep Days = $keepDays\n\n"
fi

printf "Operating on profile: \t $profile\n\n"

## Runs at the end, to decide whether to delete profiles that match chosen parameters.
choose () {
    local default="$1"
    local prompt="$2"
    local answer

    read -p "$prompt" answer
    [ -z "$answer" ] && answer="$default"

    case "$answer" in
        [yY1] ) #printf "answered yes!\n"
             nix-env --delete-generations -p $profile ${!gens[@]}
            exit 0
            ;;
        [nN0] ) printf "Ok doing nothing exiting..\n"
            exit 6;
            ;;
        *     ) printf "%b" "Unexpected answer '$answer'!" >&2
            exit 7;
            ;;
    esac
} # end of function choose

# printf "profile = $profile\n\n"
## Query nix-env for generations list
IFS=$'\n' nixGens=( $(nix-env --list-generations -p $profile | sed 's:^\s*::; s:\s*$::' | tr '\t' ' ' | tr -s ' ') )
timeNow=$(date +%s)

## Get info on oldest generation
IFS=' ' read -r -a oldestGenArr <<< "${nixGens[0]}"
oldestGen=${oldestGenArr[0]}
oldestDate=${oldestGenArr[1]}
printf "%-30s %s\n" "oldest generation:" $oldestGen
#oldestDate=${nixGens[0]:3:19}
printf "%-30s %s\n" "oldest generation created:" $oldestDate
oldestTime=$(date -d "$oldestDate" +%s)
oldestElapsedSecs=$((timeNow-oldestTime))
oldestElapsedMins=$((oldestElapsedSecs/60))
oldestElapsedHours=$((oldestElapsedMins/60))
oldestElapsedDays=$((oldestElapsedHours/24))
printf "%-30s %s\n" "minutes before now:" $oldestElapsedMins
printf "%-30s %s\n" "hours before now:" $oldestElapsedHours
printf "%-30s %s\n\n" "days before now:" $oldestElapsedDays

## Get info on current generation
for i in "${nixGens[@]}"; do
    IFS=' ' read -r -a iGenArr <<< "$i"
    genNumber=${iGenArr[0]}
    genDate=${iGenArr[1]}
    if [[ "$i" =~ current ]]; then
        currentGen=$genNumber
        printf "%-30s %s\n" "current generation:" $currentGen
        currentDate=$genDate
        printf "%-30s %s\n" "current generation created:" $currentDate
        currentTime=$(date -d "$currentDate" +%s)
        currentElapsedSecs=$((timeNow-currentTime))
        currentElapsedMins=$((currentElapsedSecs/60))
        currentElapsedHours=$((currentElapsedMins/60))
        currentElapsedDays=$((currentElapsedHours/24))
        printf "%-30s %s\n" "minutes before now:" $currentElapsedMins
        printf "%-30s %s\n" "hours before now:" $currentElapsedHours
        printf "%-30s %s\n\n" "days before now:" $currentElapsedDays
    fi
done

## Compare oldest and current generations
timeBetweenOldestAndCurrent=$((currentTime-oldestTime))
elapsedDays=$((timeBetweenOldestAndCurrent/60/60/24))
generationsDiff=$((currentGen-oldestGen))

## Figure out what we should do, based on generations and options
if [[ elapsedDays -le keepDays ]]; then
    printf "All generations are no more than $keepDays days older than current generation. \nOldest gen days difference from current gen: $elapsedDays \n\n\tNothing to do!\n"
    exit 4;
elif [[ generationsDiff -lt keepGens ]]; then
    printf "Oldest generation ($oldestGen) is only $generationsDiff generations behind current ($currentGen). \n\n\t Nothing to do!\n"
    exit 5;
else
    printf "\tSomething to do...\n"
    declare -a gens
    for i in "${nixGens[@]}"; do
        IFS=' ' read -r -a iGenArr <<< "$i"
        genNumber=${iGenArr[0]}
        genDiff=$((currentGen-genNumber))
        genDate=${iGenArr[1]}
        genTime=$(date -d "$genDate" +%s)
        elapsedSecs=$((timeNow-genTime))
        genDaysOld=$((elapsedSecs/60/60/24))
        if [[ genDaysOld -gt keepDays ]] && [[ genDiff -ge keepGens ]]; then
            gens["$genNumber"]="$genDate, $genDaysOld day(s) old"
        fi
    done
    printf "\nFound the following generation(s) to delete:\n"
    for K in "${!gens[@]}"; do
        printf "generation $K \t ${gens[$K]}\n"
    done
    printf "\n"
    choose "y" "Do you want to delete these? [Y/n]: "
fi
