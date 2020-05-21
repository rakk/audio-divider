#!/bin/bash

#
# ------------------------------------------------------------
# "THE BEERWARE LICENSE" (Revision 42):
# <author> wrote this code. As long as you retain this
# notice, you can do whatever you want with this stuff. If we
# meet someday, and you think this stuff is worth it, you can
# buy me a beer in return.
# ------------------------------------------------------------
#

usage() {
  echo "Usage: $0 \\" 1>&2;
  echo "    [-i <image-location>] \\" 1>&2;
  echo "    [-a <artist>] \\" 1>&2;
  echo "    [-s <skip>] \\                       # default 0" 1>&2;
  echo "    [-d <duration-in-seconds>] \\        # default: 120s" 1>&2;
  echo "    [-g <genre-default-audiobook>] \\    # default 'audiobook'" 1>&2;
  echo "    [-p <package-size>] \\               # default 50" 1>&2;
  echo "    [-f path-to-ffmpeg-directory] \\     # default './ffmpeg-bin/'" 1>&2;
  echo "    your-media-file " 1>&2;
  echo "" 1>&2;
  echo "    eg. $0 -f /bin -i screenshot.png -a \"Andrzej Wajda\" -d 30 my-movie.webm " 1>&2;
  echo "" 1>&2;
  exit 1;
}

displayProgress() {
  current=${1}
  duration=${2}
  allParts=${3}
  currentPart=$(( ( ${current} + ${duration} ) / ${duration} ))
  echo ""
  echo ""
  echo "    Working on ${currentPart}/${allParts}"
  echo ""
  echo ""
}

getEndPosition() {
  current=${1}
  duraction=${2}
  length=${3}

  end=$(( ${current} + ${duration} ))
  if [ ${end} -gt ${length} ]; then
    end=$(( ${length} ))
  fi
  echo "${end}"
}

processToMp3() {
  echo "Converting file: '${1}' to mp3..."
  echo "${ffmpegLocation}/ffmpeg -i \"${1}\" -metadata genre=\"${3}\" -metadata artist=\"${4}\" -acodec libmp3lame -aq 4 \"${2}\""
  ${ffmpegLocation}/ffmpeg -i "${1}" \
      -metadata genre="${3}" \
      -metadata artist="${4}" \
      -acodec libmp3lame -aq 4 "${2}"
  echo ""
  echo ""
}

ffmpegLocation="./ffmpeg-bin"
image=""
duration=$(( 2 * 60 ))
genre="audiobook"
artist=""
skip=$(( 0 ))
packageSize=$(( 50 ))

while getopts ":f:i:d:g:a:s:" o; do
    case "${o}" in
        f)
            ffmpegLocation=${OPTARG}
            ;;
        i)
            image=${OPTARG}
            ;;
        d)
            duration=${OPTARG}
            ;;
        g)
            genre=${OPTARG}
            ;;
        a)
            artist=${OPTARG}
            ;;
        s)
            skip=$(( ${OPTARG} ))
            ;;
        p)
            packageSize=$(( ${OPTARG} ))
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

filename=${1}

if [ -z "${filename}" ]; then
  usage
fi

directoryName=${filename%.*}
directoryUnifiedName=`echo "${directoryName}" | iconv -f utf-8 -t us-ascii//TRANSLIT | sed -e 's/[ ]/_/g'`

echo ""
echo "Filename: ${filename}"
echo "Duration: ${duration}s"
echo "Media length: ${length}"
echo "Directory: ${directoryUnifiedName}"
echo "Skip: ${skip}"
echo ""

mp3FileName="${directoryUnifiedName}/temp_all.mp3"

convertToMp3="true"
if [ -f "${mp3FileName}" ]; then
  read -r -p "Temp file ${mp3FileName} already exists. Override? [y/N]" response
  case "$response" in
    [yY])
        convertToMp3="true"
        ;;
    [nN])
        convertToMp3="false"
        ;;
    *)
        echo "Invalid answer. Stop processing..."
        exit 1
        ;;
   esac
fi

if [ "true" == "${convertToMp3}" ]; then
  echo "Converting to mp3..."
  processToMp3 "${filename}" "${mp3FileName}" "${artist}" "${genre}"
else
  echo "Skipping converting to mp3..."
fi

lengthString=`${ffmpegLocation}/ffprobe -i "${mp3FileName}" -show_entries format=duration -v quiet -of csv="p=0" | sed `
length=${lengthString%.*}


# add image
#if [ -n "${image}" ]; then
#  echo "Add image..."
#  mv "${mp3FileName}" "${mp3FileName}.tmp"
#  ${ffmpegLocation}/ffmpeg -i "${mp3FileName}.tmp" -i "${image}" -map_metadata 0 -map 0 -map 1 "${mp3FileName}"
#  rm "${mp3FileName}.tmp"
#fi

mkdir -p "${directoryUnifiedName}"

counter=$(( ( 000001 * ${skip} ) + 1 ))
current=$(( ${duration} * ${skip} ))
allParts=$(( ${length} / ${duration} + 1 ))

getCurrentFileName() {
  local packageSize="${1}"
  local dir="${2}"
  local counter="${3}"
  local length="${4}"
  local unifiedCounter=`printf "%03d\n" ${counter}`
  if [ ${packageSize} -lt 1 ] || [ ${packageSize} -lt ${length} ]; then
    local package=$(( ${counter} / ${packageSize} ))
    package=$(( ${package} + 1 ))
    local unifiedPackage=`printf "%02d\n" ${package}`
    if [ ! -f "${dir}/${dir}_${unifiedPackage}" ]; then
      mkdir -p "${dir}/${dir}_${unifiedPackage}"
    fi
    currentFile="${dir}_${unifiedPackage}/${unifiedCounter}_${dir}"
  else
    currentFile="${unifiedCounter}_${dir}"
  fi
  
  echo "${currentFile}"
}

while [ ${current} -lt ${length} ]
do
  displayProgress ${current} ${duration} ${allParts}

  currentFile=`getCurrentFileName ${packageSize} ${directoryUnifiedName} ${counter} ${allParts}`

  start=$(( ${current} ))
  end=`getEndPosition ${current} ${duration} ${length}`

  echo "${currentFile} -> ${start} - ${end}"
  echo ""

  currentFullFilePath=${directoryUnifiedName}/${currentFile}.mp3

  ${ffmpegLocation}/ffmpeg -i "${mp3FileName}" \
      -metadata genre="${genre}" \
      -metadata artist="${artist}" \
      -ss ${start} -t ${duration} -acodec copy "${currentFullFilePath}"
  
  tempFile=${directoryUnifiedName}/${currentFile}.tmp.mp3

  # add image
  if [ -n "${image}" ]; then
    mv "${currentFullFilePath}" "${tempFile}"
    ${ffmpegLocation}/ffmpeg -i "${tempFile}" -i "${image}" -map_metadata 0 -map 0 -map 1 "${currentFullFilePath}"
    rm "${tempFile}"
  fi

  current=$(( ${current} + ${duration} ))
  counter=$(( ${counter} + 1 ))
done
