function __fish_poetry_d6e5cd5903baca5d_complete_no_subcommand
    for i in (commandline -opc)
        if contains -- $i about add build cache check config debug env export help init install list lock new publish remove run search self shell show source update version
            return 1
        end
    end
    return 0
end

# global options
complete -c poetry -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -l ansi -d 'Force ANSI output.'
complete -c poetry -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -l directory -d 'The working directory for the Poetry command (defaults to the current working directory).'
complete -c poetry -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -l help -d 'Display help for the given command. When no command is given display help for the list command.'
complete -c poetry -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -l no-ansi -d 'Disable ANSI output.'
complete -c poetry -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -l no-cache -d 'Disables Poetry source caches.'
complete -c poetry -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -l no-interaction -d 'Do not ask any interactive question.'
complete -c poetry -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -l no-plugins -d 'Disables plugins.'
complete -c poetry -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -l quiet -d 'Do not output any message.'
complete -c poetry -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -l verbose -d 'Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.'
complete -c poetry -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -l version -d 'Display this application version.'

# commands
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a about -d 'Shows information about Poetry.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a add -d 'Adds a new dependency to pyproject.toml and installs it.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a build -d 'Builds a package, as a tarball and a wheel by default.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a cache
complete -c poetry -f -n '__fish_seen_subcommand_from cache; and not __fish_seen_subcommand_from clear list' -a clear -d 'Clears a Poetry cache by name.'
complete -c poetry -f -n '__fish_seen_subcommand_from cache; and not __fish_seen_subcommand_from clear list' -a list -d 'List Poetry\'s caches.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a check -d 'Validates the content of the pyproject.toml file and its consistency with the poetry.lock file.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a config -d 'Manages configuration settings.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a debug
complete -c poetry -f -n '__fish_seen_subcommand_from debug; and not __fish_seen_subcommand_from info resolve' -a info -d 'Shows debug information.'
complete -c poetry -f -n '__fish_seen_subcommand_from debug; and not __fish_seen_subcommand_from info resolve' -a resolve -d 'Debugs dependency resolution.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a env
complete -c poetry -f -n '__fish_seen_subcommand_from env; and not __fish_seen_subcommand_from info list remove use' -a info -d 'Displays information about the current environment.'
complete -c poetry -f -n '__fish_seen_subcommand_from env; and not __fish_seen_subcommand_from info list remove use' -a list -d 'Lists all virtualenvs associated with the current project.'
complete -c poetry -f -n '__fish_seen_subcommand_from env; and not __fish_seen_subcommand_from info list remove use' -a remove -d 'Remove virtual environments associated with the project.'
complete -c poetry -f -n '__fish_seen_subcommand_from env; and not __fish_seen_subcommand_from info list remove use' -a use -d 'Activates or creates a new virtualenv for the current project.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a export -d 'Exports the lock file to alternative formats.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a help -d 'Displays help for a command.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a init -d 'Creates a basic pyproject.toml file in the current directory.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a install -d 'Installs the project dependencies.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a list -d 'Lists commands.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a lock -d 'Locks the project dependencies.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a new -d 'Creates a new Python project at <path>.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a publish -d 'Publishes a package to a remote repository.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a remove -d 'Removes a package from the project dependencies.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a run -d 'Runs a command in the appropriate environment.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a search -d 'Searches for packages on remote repositories.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a self
complete -c poetry -f -n '__fish_seen_subcommand_from self; and not __fish_seen_subcommand_from add install lock remove update show' -a add -d 'Add additional packages to Poetry\'s runtime environment.'
complete -c poetry -f -n '__fish_seen_subcommand_from self; and not __fish_seen_subcommand_from add install lock remove update show' -a install -d 'Install locked packages (incl. addons) required by this Poetry installation.'
complete -c poetry -f -n '__fish_seen_subcommand_from self; and not __fish_seen_subcommand_from add install lock remove update show' -a lock -d 'Lock the Poetry installation\'s system requirements.'
complete -c poetry -f -n '__fish_seen_subcommand_from self; and not __fish_seen_subcommand_from add install lock remove update show' -a remove -d 'Remove additional packages from Poetry\'s runtime environment.'
complete -c poetry -f -n '__fish_seen_subcommand_from self; and not __fish_seen_subcommand_from add install lock remove update show' -a show -d 'Show packages from Poetry\'s runtime environment.'
complete -c poetry -f -n '__fish_seen_subcommand_from self; and not __fish_seen_subcommand_from add install lock remove update show' -a plugins -d 'Shows information about the currently installed plugins.'
complete -c poetry -f -n '__fish_seen_subcommand_from self; and not __fish_seen_subcommand_from add install lock remove update show' -a update -d 'Updates Poetry to the latest version.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a shell -d 'Spawns a shell within the virtual environment.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a show -d 'Shows information about packages.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a source
complete -c poetry -f -n '__fish_seen_subcommand_from source; and not __fish_seen_subcommand_from add remove show' -a add -d 'Add source configuration for project.'
complete -c poetry -f -n '__fish_seen_subcommand_from source; and not __fish_seen_subcommand_from add remove show' -a remove -d 'Remove source configured for the project.'
complete -c poetry -f -n '__fish_seen_subcommand_from source; and not __fish_seen_subcommand_from add remove show' -a show -d 'Show information about sources configured for the project.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a update -d 'Update the dependencies as according to the pyproject.toml file.'
complete -c poetry -f -n '__fish_poetry_d6e5cd5903baca5d_complete_no_subcommand' -a version -d 'Shows the version of the project or bumps it when a valid bump rule is provided.'

# command options

# about

# add
complete -c poetry -n '__fish_seen_subcommand_from add' -l allow-prereleases -d 'Accept prereleases.'
complete -c poetry -n '__fish_seen_subcommand_from add' -l dev -d 'Add as a development dependency. (Deprecated) Use --group=dev instead.'
complete -c poetry -n '__fish_seen_subcommand_from add' -l dry-run -d 'Output the operations but do not execute anything (implicitly enables --verbose).'
complete -c poetry -n '__fish_seen_subcommand_from add' -l editable -d 'Add vcs/path dependencies as editable.'
complete -c poetry -n '__fish_seen_subcommand_from add' -l extras -d 'Extras to activate for the dependency.'
complete -c poetry -n '__fish_seen_subcommand_from add' -l group -d 'The group to add the dependency to.'
complete -c poetry -n '__fish_seen_subcommand_from add' -l lock -d 'Do not perform operations (only update the lockfile).'
complete -c poetry -n '__fish_seen_subcommand_from add' -l optional -d 'Add as an optional dependency.'
complete -c poetry -n '__fish_seen_subcommand_from add' -l platform -d 'Platforms for which the dependency must be installed.'
complete -c poetry -n '__fish_seen_subcommand_from add' -l python -d 'Python version for which the dependency must be installed.'
complete -c poetry -n '__fish_seen_subcommand_from add' -l source -d 'Name of the source to use to install the package.'

# build
complete -c poetry -n '__fish_seen_subcommand_from build' -l format -d 'Limit the format to either sdist or wheel.'
complete -c poetry -n '__fish_seen_subcommand_from build' -l output -d 'Set output directory for build artifacts. Default is `dist`.'

# cache clear
complete -c poetry -n '__fish_seen_subcommand_from cache; and __fish_seen_subcommand_from clear' -l all -d 'Clear all entries in the cache.'

# cache list

# check
complete -c poetry -n '__fish_seen_subcommand_from check' -l lock -d 'Checks that poetry.lock exists for the current version of pyproject.toml.'

# config
complete -c poetry -n '__fish_seen_subcommand_from config' -l list -d 'List configuration settings.'
complete -c poetry -n '__fish_seen_subcommand_from config' -l local -d 'Set/Get from the project\'s local configuration.'
complete -c poetry -n '__fish_seen_subcommand_from config' -l unset -d 'Unset configuration setting.'

# debug info

# debug resolve
complete -c poetry -n '__fish_seen_subcommand_from debug; and __fish_seen_subcommand_from resolve' -l extras -d 'Extras to activate for the dependency.'
complete -c poetry -n '__fish_seen_subcommand_from debug; and __fish_seen_subcommand_from resolve' -l install -d 'Show what would be installed for the current system.'
complete -c poetry -n '__fish_seen_subcommand_from debug; and __fish_seen_subcommand_from resolve' -l python -d 'Python version(s) to use for resolution.'
complete -c poetry -n '__fish_seen_subcommand_from debug; and __fish_seen_subcommand_from resolve' -l tree -d 'Display the dependency tree.'

# env info
complete -c poetry -n '__fish_seen_subcommand_from env; and __fish_seen_subcommand_from info' -l executable -d 'Only display the environment\'s python executable path.'
complete -c poetry -n '__fish_seen_subcommand_from env; and __fish_seen_subcommand_from info' -l path -d 'Only display the environment\'s path.'

# env list
complete -c poetry -n '__fish_seen_subcommand_from env; and __fish_seen_subcommand_from list' -l full-path -d 'Output the full paths of the virtualenvs.'

# env remove
complete -c poetry -n '__fish_seen_subcommand_from env; and __fish_seen_subcommand_from remove' -l all -d 'Remove all managed virtual environments associated with the project.'

# env use

# export
complete -c poetry -n '__fish_seen_subcommand_from export' -l all-extras -d 'Include all sets of extra dependencies.'
complete -c poetry -n '__fish_seen_subcommand_from export' -l dev -d 'Include development dependencies. (Deprecated)'
complete -c poetry -n '__fish_seen_subcommand_from export' -l extras -d 'Extra sets of dependencies to include.'
complete -c poetry -n '__fish_seen_subcommand_from export' -l format -d 'Format to export to. Currently, only constraints.txt and requirements.txt are supported.'
complete -c poetry -n '__fish_seen_subcommand_from export' -l only -d 'The only dependency groups to include.'
complete -c poetry -n '__fish_seen_subcommand_from export' -l output -d 'The name of the output file.'
complete -c poetry -n '__fish_seen_subcommand_from export' -l with -d 'The optional dependency groups to include.'
complete -c poetry -n '__fish_seen_subcommand_from export' -l with-credentials -d 'Include credentials for extra indices.'
complete -c poetry -n '__fish_seen_subcommand_from export' -l without -d 'The dependency groups to ignore.'
complete -c poetry -n '__fish_seen_subcommand_from export' -l without-hashes -d 'Exclude hashes from the exported file.'
complete -c poetry -n '__fish_seen_subcommand_from export' -l without-urls -d 'Exclude source repository urls from the exported file.'

# help

# init
complete -c poetry -n '__fish_seen_subcommand_from init' -l author -d 'Author name of the package.'
complete -c poetry -n '__fish_seen_subcommand_from init' -l dependency -d 'Package to require, with an optional version constraint, e.g. requests:^2.10.0 or requests=2.11.1.'
complete -c poetry -n '__fish_seen_subcommand_from init' -l description -d 'Description of the package.'
complete -c poetry -n '__fish_seen_subcommand_from init' -l dev-dependency -d 'Package to require for development, with an optional version constraint, e.g. requests:^2.10.0 or requests=2.11.1.'
complete -c poetry -n '__fish_seen_subcommand_from init' -l license -d 'License of the package.'
complete -c poetry -n '__fish_seen_subcommand_from init' -l name -d 'Name of the package.'
complete -c poetry -n '__fish_seen_subcommand_from init' -l python -d 'Compatible Python versions.'

# install
complete -c poetry -n '__fish_seen_subcommand_from install' -l all-extras -d 'Install all extra dependencies.'
complete -c poetry -n '__fish_seen_subcommand_from install' -l compile -d 'Compile Python source files to bytecode. (This option has no effect if modern-installation is disabled because the old installer always compiles.)'
complete -c poetry -n '__fish_seen_subcommand_from install' -l dry-run -d 'Output the operations but do not execute anything (implicitly enables --verbose).'
complete -c poetry -n '__fish_seen_subcommand_from install' -l extras -d 'Extra sets of dependencies to install.'
complete -c poetry -n '__fish_seen_subcommand_from install' -l no-dev -d 'Do not install the development dependencies. (Deprecated)'
complete -c poetry -n '__fish_seen_subcommand_from install' -l no-directory -d 'Do not install any directory path dependencies; useful to install dependencies without source code, e.g. for caching of Docker layers)'
complete -c poetry -n '__fish_seen_subcommand_from install' -l no-root -d 'Do not install the root package (the current project).'
complete -c poetry -n '__fish_seen_subcommand_from install' -l only -d 'The only dependency groups to include.'
complete -c poetry -n '__fish_seen_subcommand_from install' -l only-root -d 'Exclude all dependencies.'
complete -c poetry -n '__fish_seen_subcommand_from install' -l remove-untracked -d 'Removes packages not present in the lock file. (Deprecated)'
complete -c poetry -n '__fish_seen_subcommand_from install' -l sync -d 'Synchronize the environment with the locked packages and the specified groups.'
complete -c poetry -n '__fish_seen_subcommand_from install' -l with -d 'The optional dependency groups to include.'
complete -c poetry -n '__fish_seen_subcommand_from install' -l without -d 'The dependency groups to ignore.'

# list

# lock
complete -c poetry -n '__fish_seen_subcommand_from lock' -l check -d 'Check that the poetry.lock file corresponds to the current version of pyproject.toml. (Deprecated) Use poetry check --lock instead.'
complete -c poetry -n '__fish_seen_subcommand_from lock' -l no-update -d 'Do not update locked versions, only refresh lock file.'

# new
complete -c poetry -n '__fish_seen_subcommand_from new' -l name -d 'Set the resulting package name.'
complete -c poetry -n '__fish_seen_subcommand_from new' -l readme -d 'Specify the readme file format. Default is md.'
complete -c poetry -n '__fish_seen_subcommand_from new' -l src -d 'Use the src layout for the project.'

# publish
complete -c poetry -n '__fish_seen_subcommand_from publish' -l build -d 'Build the package before publishing.'
complete -c poetry -n '__fish_seen_subcommand_from publish' -l cert -d 'Certificate authority to access the repository.'
complete -c poetry -n '__fish_seen_subcommand_from publish' -l client-cert -d 'Client certificate to access the repository.'
complete -c poetry -n '__fish_seen_subcommand_from publish' -l dist-dir -d 'Dist directory where built artifact are stored. Default is `dist`.'
complete -c poetry -n '__fish_seen_subcommand_from publish' -l dry-run -d 'Perform all actions except upload the package.'
complete -c poetry -n '__fish_seen_subcommand_from publish' -l password -d 'The password to access the repository.'
complete -c poetry -n '__fish_seen_subcommand_from publish' -l repository -d 'The repository to publish the package to.'
complete -c poetry -n '__fish_seen_subcommand_from publish' -l skip-existing -d 'Ignore errors from files already existing in the repository.'
complete -c poetry -n '__fish_seen_subcommand_from publish' -l username -d 'The username to access the repository.'

# remove
complete -c poetry -n '__fish_seen_subcommand_from remove' -l dev -d 'Remove a package from the development dependencies. (Deprecated) Use --group=dev instead.'
complete -c poetry -n '__fish_seen_subcommand_from remove' -l dry-run -d 'Output the operations but do not execute anything (implicitly enables --verbose).'
complete -c poetry -n '__fish_seen_subcommand_from remove' -l group -d 'The group to remove the dependency from.'
complete -c poetry -n '__fish_seen_subcommand_from remove' -l lock -d 'Do not perform operations (only update the lockfile).'

# run

# search

# self add
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from add' -l allow-prereleases -d 'Accept prereleases.'
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from add' -l dry-run -d 'Output the operations but do not execute anything (implicitly enables --verbose).'
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from add' -l editable -d 'Add vcs/path dependencies as editable.'
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from add' -l extras -d 'Extras to activate for the dependency.'
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from add' -l source -d 'Name of the source to use to install the package.'

# self install
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from install' -l dry-run -d 'Output the operations but do not execute anything (implicitly enables --verbose).'
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from install' -l sync -d 'Synchronize the environment with the locked packages and the specified groups.'

# self lock
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from lock' -l check -d 'Check that the poetry.lock file corresponds to the current version of pyproject.toml. (Deprecated) Use poetry check --lock instead.'
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from lock' -l no-update -d 'Do not update locked versions, only refresh lock file.'

# self remove
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from remove' -l dry-run -d 'Output the operations but do not execute anything (implicitly enables --verbose).'

# self show
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from show' -l addons -d 'List only add-on packages installed.'
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from show' -l latest -d 'Show the latest version.'
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from show' -l outdated -d 'Show the latest version but only for packages that are outdated.'
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from show' -l tree -d 'List the dependencies as a tree.'

# self show plugins

# self update
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from update' -l dry-run -d 'Output the operations but do not execute anything (implicitly enables --verbose).'
complete -c poetry -n '__fish_seen_subcommand_from self; and __fish_seen_subcommand_from update' -l preview -d 'Allow the installation of pre-release versions.'

# shell

# show
complete -c poetry -n '__fish_seen_subcommand_from show' -l all -d 'Show all packages (even those not compatible with current system).'
complete -c poetry -n '__fish_seen_subcommand_from show' -l latest -d 'Show the latest version.'
complete -c poetry -n '__fish_seen_subcommand_from show' -l no-dev -d 'Do not list the development dependencies. (Deprecated)'
complete -c poetry -n '__fish_seen_subcommand_from show' -l only -d 'The only dependency groups to include.'
complete -c poetry -n '__fish_seen_subcommand_from show' -l outdated -d 'Show the latest version but only for packages that are outdated.'
complete -c poetry -n '__fish_seen_subcommand_from show' -l top-level -d 'Show only top-level dependencies.'
complete -c poetry -n '__fish_seen_subcommand_from show' -l tree -d 'List the dependencies as a tree.'
complete -c poetry -n '__fish_seen_subcommand_from show' -l why -d 'When showing the full list, or a --tree for a single package, display whether they are a direct dependency or required by other packages'
complete -c poetry -n '__fish_seen_subcommand_from show' -l with -d 'The optional dependency groups to include.'
complete -c poetry -n '__fish_seen_subcommand_from show' -l without -d 'The dependency groups to ignore.'

# source add
complete -c poetry -n '__fish_seen_subcommand_from source; and __fish_seen_subcommand_from add' -l default -d 'Set this source as the default (disable PyPI). A default source will also be the fallback source if you add other sources. (Deprecated, use --priority)'
complete -c poetry -n '__fish_seen_subcommand_from source; and __fish_seen_subcommand_from add' -l priority -d 'Set the priority of this source. One of: default, primary, secondary, supplemental, explicit. Defaults to primary.'
complete -c poetry -n '__fish_seen_subcommand_from source; and __fish_seen_subcommand_from add' -l secondary -d 'Set this source as secondary. (Deprecated, use --priority)'

# source remove

# source show

# update
complete -c poetry -n '__fish_seen_subcommand_from update' -l dry-run -d 'Output the operations but do not execute anything (implicitly enables --verbose).'
complete -c poetry -n '__fish_seen_subcommand_from update' -l lock -d 'Do not perform operations (only update the lockfile).'
complete -c poetry -n '__fish_seen_subcommand_from update' -l no-dev -d 'Do not update the development dependencies. (Deprecated)'
complete -c poetry -n '__fish_seen_subcommand_from update' -l only -d 'The only dependency groups to include.'
complete -c poetry -n '__fish_seen_subcommand_from update' -l sync -d 'Synchronize the environment with the locked packages and the specified groups.'
complete -c poetry -n '__fish_seen_subcommand_from update' -l with -d 'The optional dependency groups to include.'
complete -c poetry -n '__fish_seen_subcommand_from update' -l without -d 'The dependency groups to ignore.'

# version
complete -c poetry -n '__fish_seen_subcommand_from version' -l dry-run -d 'Do not update pyproject.toml file'
complete -c poetry -n '__fish_seen_subcommand_from version' -l next-phase -d 'Increment the phase of the current version'
complete -c poetry -n '__fish_seen_subcommand_from version' -l short -d 'Output the version number only'
