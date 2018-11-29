#!/bin/bash
ROOT_DIR=$(dirname "$(realpath "$0")")
PATH=$PATH:"$ROOT_DIR"

REPO_DIR=$ROOT_DIR'/repos/casting_geometric_toolsuite'
OPT_DEMO_DIR=$REPO_DIR'/examples/optimization_demo'
STL_NAME=$1
STL_PATH=$ROOT_DIR'/oo_stl/'$STL_NAME
OPTIONS_NAME='oo_options.json'
OPTIONS_PATH=$OPT_DEMO_DIR'/'$OPTIONS_NAME
OBJECTIVE_NAME='objective_variables.json'
OBJECTIVE_PATH=$OPT_DEMO_DIR'/'$OBJECTIVE_NAME
OUTPUT_PATH=$ROOT_DIR'/results'
RUN_CMD='generate_csvs_on_hpc( '\'$STL_PATH\'', '\'$OPTIONS_PATH\'', '\'$OBJECTIVE_PATH\'', [$ANGLES], $SLURM_ARRAY_TASK_ID, $SLURM_JOB_ID, '\'$OUTPUT_PATH\'' );'
FULL_CMD=$( create_matlab_command -a -c $REPO_DIR -d $ROOT_DIR -f "$RUN_CMD" )

CSV_NAME='sphere_angles.csv'
CSV_PATH=$ROOT_DIR'/'$CSV_NAME
NAME=oo_project
ARRAYMAX=$(( $( wc -l < $CSV_PATH ) -1 ))
MAXTASKS=64
TASKS=1
MEMORY='20GB'
TIME=2:00:00
PARTITION=express
MAILTYPE=FAIL
MAILADDRESS='wwarr@uab.edu'

module load rc/matlab/R2018a
JOB_ID=$( sbatch --array=0-1%$MAXTASKS --job-name=$NAME --output=output/output_%A_%a.txt --ntasks=$TASKS --mem-per-cpu=$MEMORY --time=$TIME --partition=$PARTITION --mail-type=$MAILTYPE --mail-user=$MAILADDRESS <<LIMITING_STRING
#!/bin/bash
ANGLES=\$( sed \$(( \$SLURM_ARRAY_TASK_ID+1 ))'q;d' $CSV_PATH )
matlab -nodisplay -nodesktop -sd $ROOT_DIR -r $FULL_CMD
LIMITING_STRING
)
JOB_ID=${JOB_ID##* }
printf '%s\n' "$JOB_ID"

copy_file()
{
	DIR=`dirname "$1"`
	BASENAME=`basename "$1"`
	EXT=".${BASENAME##*.}"
	NAME="${BASENAME%.*}"
	
	OUT_DIR="$2"
	JOB_ID="$3"
	CP_PATH="$OUT_DIR"'/'"$NAME"'_'"$JOB_ID""$EXT"
	cp -fp "$1" "$CP_PATH"
}

copy_file "$OBJECTIVE_PATH" "$OUTPUT_PATH" "$JOB_ID"
copy_file "$STL_PATH" "$OUTPUT_PATH" "$JOB_ID"
copy_file "$CSV_PATH" "$OUTPUT_PATH" "$JOB_ID"
copy_file "$OPTIONS_PATH" "$OUTPUT_PATH" "$JOB_ID"