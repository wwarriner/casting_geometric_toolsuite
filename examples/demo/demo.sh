#!/bin/bash
SHELL_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SHELL_DIR/../../../..")
PATH=$PATH:"$ROOT_DIR"
COMPONENT_NAME=$1

REPOS_DIR=$ROOT_DIR'/repos'
STL_DIR=$ROOT_DIR'/demo_stl'
STL_FILE=$STL_DIR'/'$COMPONENT_NAME'.stl'
if [ ! -f "$STL_FILE" ]; then
	printf "Can't located STL FILE: %s\n" $STL_FILE
	exit
fi

# Toolsuite
CGT_DIR=$REPOS_DIR'/casting_geometric_toolsuite'
if [ ! -d "$CGT_DIR" ]; then
	printf "Can't locate CGT_DIR: %s\n" $CGT_DIR
	exit
fi
DEMO_SETTINGS=$CGT_DIR'/examples/demo/res/demo_settings.json'
if [ ! -f "$DEMO_SETTINGS" ]; then
	printf "Can't locate DEMO SETTINGS: %s\n" $DEMO_SETTINGS
	exit
fi

TIME=$(date +%s%N)
OUTPUT_BASE_PATH=$ROOT_DIR'/demo_results/'$COMPONENT_NAME
OUTPUT_PATH=$OUTPUT_BASE_PATH'_'$TIME
mkdir -p $OUTPUT_PATH

RUN_CMD='addpath( genpath( '\'$CGT_DIR\'' ) );demo_fn( '\'$DEMO_SETTINGS\'', '\'$STL_FILE\'', '\'$OUTPUT_PATH\'' );exit;'

NAME=oo_project
TASKS=1
MEMORY='30GB'
TIME=2:00:00
PARTITION=express
MAILTYPE=FAIL
MAILADDRESS='wwarr@uab.edu'

#0-$ARRAYMAX
sbatch --array=0%1 --job-name $NAME --output=$ROOT_DIR/output/output_%A.txt --ntasks=$TASKS --mem-per-cpu=$MEMORY --time=$TIME --partition=$PARTITION --mail-type=$MAILTYPE --mail-user=$MAILADDRESS <<LIMITING_STRING
#!/bin/bash
module load rc/matlab/R2019a
matlab -nodesktop -nodisplay -sd "$REPOS_DIR" -r "$RUN_CMD"
LIMITING_STRING
