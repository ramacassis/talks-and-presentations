#! /bin/sh

# Name: edit_video.sh
# Date: 2020/04/03
# Purpose: Edit a video depending on used options

#   Following options are currently supported:
#   --snap: take a picture inside the video (using gimp you can then determine the offset to crop from)
#   --crop: crop the whole video

#------------------------------------------------------------------------------
# CONSTANTS
#------------------------------------------------------------------------------

SNAP_TIMESTAMP="00:30:00"

CROP_X_ORIG=0
CROP_Y_ORIG=90
CROP_OUTPUT_WIDTH=960
CROP_OUTPUT_HEIGHT=540

OUTPUT_DIR="./edit_video_out"
LOGFILE="${OUTPUT_DIR}/logs.txt"


#------------------------------------------------------------------------------
# GLOBALS
#------------------------------------------------------------------------------

g_crop=false
g_snap=false

g_errnb=0

declare -a videosArray


#------------------------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------------------------

f_usage()
{
    echo "Usage:"
    echo ""
    echo "  ./edit_video.sh [--snap] [--crop] <video1> <video2> [...]"

    echo ""
    echo "Example:"
    echo ""
    echo "  ./edit_video.sh --crop *.mp4"

    echo ""
    echo "--------------------------------------------------"
    echo ""

    echo "By default snapshots will be taken at 00:30:00 (30 minutes)"
    echo "Crop settings are currently hardcoded with the following values:"
    echo ""
    echo "  X origin: ${CROP_X_ORIG}"
    echo "  Y origin: ${CROP_Y_ORIG}"
    echo "  Output width: ${CROP_OUTPUT_WIDTH}"
    echo "  Output height: ${CROP_OUTPUT_HEIGHT}"
    echo ""
    echo "--> Please change default values in script if needed."
}

f_edit_video()
{
    local l_video="$1"
    local l_videoBasename=$(basename "${l_video}")
    local l_filename="${l_videoBasename%.*}"

    # TODO: Make separate functions ?

    # Snapshot
    if [ "${g_snap}" = "true" ]; then

        l_outputFilename="${l_filename}_snapshot.png"
        l_reportMsg="Snapshot has been taken at ${SNAP_TIMESTAMP}, output file: ${l_outputFilename}"

        ffmpeg -y -ss ${SNAP_TIMESTAMP} -i ${l_video} -vframes 1 ${OUTPUT_DIR}/${l_outputFilename} &>> ${LOGFILE}

        # Output details
        if [ $? -ne 0 ]; then
            echo "An error occured taking snapshot of video '${l_videoBasename}'"
            ((g_errnb++))
        else
            echo "${l_reportMsg}"
        fi
    fi

    # Crop
    if [ "${g_crop}" = "true" ]; then

        l_outputFilename="${l_filename}_cropped.mp4"
        l_reportMsg="Video has been cropped, output file: ${l_outputFilename}"

        ffmpeg -y -i ${l_video} -filter:v "crop=${CROP_OUTPUT_WIDTH}:${CROP_OUTPUT_HEIGHT}:${CROP_X_ORIG}:${CROP_Y_ORIG}"\
            ${OUTPUT_DIR}/${l_outputFilename} &>> ${LOGFILE}

        # Output details
        if [ $? -ne 0 ]; then
            echo "An error occured cropping video '${l_videoBasename}'"
            ((g_errnb++))
        else
            echo "${l_reportMsg}"
        fi
    fi
}

f_parse_cmd()
{
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            -h|--help)
                f_usage
                exit 0
                ;;
            -s|--snap)
                g_snap=true
                shift
                ;;
            -c|--crop)
                g_crop=true
                shift
                ;;
            *)
                videosArray+=("$1")
                shift
                ;;
        esac
    done
}


#-------------------------------------------------------------------------------
# CORE
#-------------------------------------------------------------------------------

f_parse_cmd $@

if [ "${g_snap}" = "true" ] || [ "${g_crop}" = "true" ]; then

    rm -rf ${OUTPUT_DIR}
    mkdir -p ${OUTPUT_DIR}

    for video in "${videosArray[@]}"; do
        echo "Processing ${video}..."
        f_edit_video ${video}
    done

    # Error handling
    if [ ${g_errnb} -eq 0 ]; then
        echo "End of program, all operations have been successfully performed"
        exit 0
    else
        echo "End of program, number of errors: ${g_errnb}"
        exit 1
    fi

else
    echo "Error: An option must be specified"
    echo ""
    f_usage
    exit 0
fi
