#!/bin/sh
# Fist argument is the type of accelerator usally intel mkl or openblas
# second is the base dir for the problems
OUTFILE="results/outfile_$(hostname -s)_$(date +%d%m)_${1}"

problempath=${2:-'../problems/'}
TYPE=${3:-'multid'}

[ -d "$problempath" ] || exit 1
[ -e "./benchmark_${TYPE}.py" ] || exit 1

benchmark(){
    perf=$1
    threads=$2
    problem=$3
    numba=$4
    delay=1000

    export OPENBLAS_NUM_THREADS=$threads
    export MKL_NUM_THREADS=$threads
    export NUMEXPR_NUM_THREADS=$threads
    export VECLIB_MAXIMUM_THREADS=$threads
    export OMP_NUM_THREADS=$threads
    export NUMBA_NUM_THREADS=$threads
    cmd="./benchmark_${TYPE}.py $([ $TYPE = 'gsrb' ] && echo '-v' ) -p $problem -d $delay $numba"
    if [ "$perf" = true ]
    then
        cmd="perf stat -M GFLOPS -D $delay $cmd"
    fi

<<<<<<< HEAD
    x=$($cmd 2>&1 || exit 1)
    out=$(echo "$x" | head -n 2 | tr '\n' ':' | tr ' ' ':' | awk -F':' '{print $12 ":" $5 ":" $8 ":"}')
=======
    x=$($cmd 2>&1)  || exit 1
    if [ $TYPE = 'multid' ]
    then
        out=$(echo "$x" | head -n 2 | tr '\n' ':' | tr ' ' ':' | awk -F':' '{print $12 ":" $5 ":" $8 ":"}')
    fi
    if [ $TYPE = 'gsrb' ]
    then
        out=$(echo "$x" | head -n 1 | awk -F':' '{print $3 ":0:0:"}')
    fi
>>>>>>> 1545531f7974b55f985a751796b5b8fc6d5875fa


    if [ "$perf" = true ]
    then
        flops=$(echo "$x" | tail -n +3 | grep -i 'fp' | awk '{ print $1}' | tr '\n' ':')
        out="$out$flops"
    fi

    printf "%s\n" "$out"

}



paranoid=$(cat /proc/sys/kernel/perf_event_paranoid)
perf=false
reps=3
if [ "$paranoid" -lt 3 ]  && perf list eventgroups | grep -q FLOPS
then
    perf=true
fi

get_infos(){
    ../scripts/getinfos.sh "np" "$perf"
}

[ -e "${OUTFILE}_1_numba_${TYPE}" ] || get_infos >> "${OUTFILE}_1_numba_${TYPE}" || exit 1
[ -e "${OUTFILE}_8_numba_${TYPE}" ] || get_infos >> "${OUTFILE}_8_numba_${TYPE}" || exit 1
[ -e "${OUTFILE}_1_nonumba_${TYPE}" ] || get_infos >> "${OUTFILE}_1_nonumba_${TYPE}" || exit 1
[ -e "${OUTFILE}_8_nonumba_${TYPE}" ] || get_infos >> "${OUTFILE}_8_nonumba_${TYPE}" || exit 1


for problem in "$problempath/"*.npy; do
    dim=$(echo "$problem" | awk -F'_' '{print $2}')
    N=$(echo "$problem" | awk -F'_' '{print $3}')
    N=${N%%\.npy}

    echo $problem

    for threads in 1 8; do
        for numba in "-n" " "; do

            for _ in $(seq $reps); do
                # x=$(perf stat -M GFLOPS ./measure.py $N "$numba" 2>&1 | grep -i 'fp\|elapsed' | awk '{ print $1}' | tr '\n' ':')
                EXTENSION=$([ "$numba" = " " ] && echo "nonumba" || echo "numba")
                x=$(benchmark $perf $threads "$problem" "$numba") || break
                printf "%b:%b:%b\n" "$N" "$dim" "$x" >> "${OUTFILE}_${threads}_${EXTENSION}_${TYPE}"
            done
        done
    done
done

exit 0
