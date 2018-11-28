#!/bin/bash
ROOT_DIR=$(dirname "$(realpath "$0")")
PATH=$PATH:"$ROOT_DIR"

CD_DIR=$ROOT_DIR'/repos/casting_geometric_toolsuite'
STL_NAME=$1
STL_PATH=$ROOT_DIR'/oo_stl/'$STL_NAME
CSV_NAME='sphere_angles.csv'
CSV_PATH=$ROOT_DIR'/'$CSV_NAME
OUTPUT_PATH=$ROOT_DIR'/results'
OPTIONS_PATH=$ROOT_DIR'/oo_options.json'
RUN_CMD='generate_csvs_on_hpc( '\'$STL_PATH\'', '\'$OPTIONS_PATH\'', [$ANGLES], $SLURM_ARRAY_TASK_ID, $SLURM_JOB_ID, '\'$OUTPUT_PATH\'' );'
FULL_CMD=$( create_matlab_command -a -c $CD_DIR -d $ROOT_DIR -f "$RUN_CMD" )

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
JOB_ID=$( sbatch --array=0-$ARRAYMAX%$MAXTASKS --job-name=$NAME --output=output/output_%A_%a.txt --ntasks=$TASKS --mem-per-cpu=$MEMORY --time=$TIME --partition=$PARTITION --mail-type=$MAILTYPE --mail-user=$MAILADDRESS <<LIMITING_STRING
#!/bin/bash
ANGLES=\$( sed \$(( \$SLURM_ARRAY_TASK_ID+1 ))'q;d' $CSV_PATH )
matlab -nodisplay -nodesktop -sd $ROOT_DIR -r $FULL_CMD
LIMITING_STRING )

OBJECTIVE_NAME='objective_variables.json'
OBJECTIVE_PATH=$CD_DIR'/'$OBJECTIVE_NAME
OBJECTIVE_CP_NAME='objective_variables_'$JOB_ID'.json'
OBJECTIVE_CP_PATH=$CD_DIR'/'$OBJECTIVE_CP_NAME
cp -fp $OBJECTIVE_PATH $OBJECTIVE_CP_PATH