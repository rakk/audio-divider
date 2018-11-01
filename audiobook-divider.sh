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
  echo "    [-s <skip>] \\ # default 0" 1>&2;
  echo "    [-d <duration-in-seconds>] \\ # default: 120s" 1>&2;
  echo "    [-g <genre-default-audiobook>] \\ # default 'audiobook'" 1>&2;
  echo "    [-f path-to-ffmpeg-directory] \\ # default './ffmpeg-bin/'" 1>&2;
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

ffmpegLocation="./ffmpeg-bin"
image=""
duration=$(( 2 * 60 ))
genre="audiobook"
artist=""
skip=$(( 0 ))

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

lengthString=`${ffmpegLocation}/ffprobe -i "${filename}" -show_entries format=duration -v quiet -of csv="p=0" | sed `
length=${lengthString%.*}
directoryName=${filename%.*}
directoryUnifiedName=`echo "${directoryName}" | iconv -f utf-8 -t us-ascii//TRANSLIT | sed -e 's/[ ]/_/g'`

echo ""
echo "Filename: ${filename}"
echo "Duration: ${duration}s"
echo "Media length: ${length}"
echo "Directory: ${directoryUnifiedName}"
echo "Skip: ${skip}"
echo ""

mkdir -p "${directoryUnifiedName}"

counter=$(( 000001 * ${skip} ))
current=$(( ${duration} * ${skip} ))
allParts=$(( ${length} / ${duration} + 1))

while [ ${current} -lt ${length} ]
do
  displayProgress ${current} ${duration} ${allParts}

  unifiedCounter=`printf "%03d\n" $counter`
  currentFile=${unifiedCounter}_${directoryUnifiedName}

  start=$(( ${current} ))
  end=`getEndPosition ${current} ${duration} ${length}`

  echo "${currentFile} -> ${start} - ${end}"
  echo ""

  currentFullFilePath=${directoryUnifiedName}/${currentFile}.mp3

  ${ffmpegLocation}/ffmpeg -i "${filename}" \
      -metadata genre="${genre}" \
      -metadata artist="${artist}" \
      -ss ${start} -c copy -t ${duration} -acodec libmp3lame -aq 4 "${currentFullFilePath}"

  tempFile=${directoryUnifiedName}/${currentFile}.tmp.mp3

  # add image
  if [ -n "${image}" ]; then
    mv "${currentFullFilePath}" "${tempFile}"
    echo ""
    echo "${ffmpegLocation}/ffmpeg -i \"${tempFile}\" -i \"${image}\" -map_metadata 0 -map 0 -map 1 \"${currentFullFilePath}\""
    echo ""
    ${ffmpegLocation}/ffmpeg -i "${tempFile}" -i "${image}" -map_metadata 0 -map 0 -map 1 "${currentFullFilePath}"
    rm "${tempFile}"
  fi

  current=$(( ${current} + ${duration} ))
  counter=$(( ${counter} + 1 ))
done
