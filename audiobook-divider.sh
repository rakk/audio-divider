#!/bin/bash

usage() {
  echo "Usage: $0 [-f path-to-ffmpeg]" 1>&2;
  echo "    [-i <image-location>] [-d <duration-in-seconds>]" 1>&2;
  echo "    [-g <genre-default-audiobook>] [-a <author>]"
  echo "    your-media-file " 1>&2;
  echo "" 1>&2;
  echo "    eg. $0 -f /bin/ffmpeg -i screenshot.png -d 30 my-movie.webm " 1>&2;
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

ffmpegLocation="./ffmpeg"
image=""
duration=$(( 2 * 60 ))
genre="audiobook"
author=""

while getopts ":f:i:d:g:a:" o; do
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
            author=${OPTARG}
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

lengthString=`./ffprobe -i "${filename}" -show_entries format=duration -v quiet -of csv="p=0" | sed `
length=${lengthString%.*}
directoryName=${filename%.*}
directoryUnifiedName=`echo "${directoryName}" | iconv -f utf-8 -t us-ascii//TRANSLIT | sed -e 's/[ ]/_/g'`

echo ""
echo "Filename: ${filename}"
echo "Duration: ${duration}s"
echo "Media length: ${length}"
echo "Directory: ${directoryUnifiedName}"
echo ""

mkdir -p "${directoryUnifiedName}"

counter=$(( 000001 ))
current=$(( 0 ))
allParts=$(( ${length} / ${duration} + 1))

# while [ ${current} -lt ${length} ]
while [ ${current} -lt 1 ]
do
  displayProgress ${current} ${duration} ${allParts}

  unifiedCounter=`printf "%03d\n" $counter`
  currentFile=${unifiedCounter}_${directoryUnifiedName}

  start=$(( ${current} ))
  end=`getEndPosition ${current} ${duration} ${length}`

  echo "${currentFile} -> ${start} - ${end}"
  echo ""

  currentFullFilePath=${directoryUnifiedName}/${currentFile}.mp3
  echo "${ffmpegLocation} -i \"${filename}\" -ss ${start} -c copy -t ${duration} -acodec libmp3lame -aq 4 \"${currentFullFilePath}\""
  ${ffmpegLocation} -i "${filename}" -ss ${start} -c copy -t ${duration} -acodec libmp3lame -aq 4 "${currentFullFilePath}"

  tempFile=${directoryUnifiedName}/${currentFile}.tmp.mp3

  # update genre
  mv "${currentFullFilePath}" "${tempFile}"
  echo ""
  echo "${ffmpegLocation} -i \"${tempFile}\" -metadata:s:v genre=\"${genre}\" ${authorPart} \"${currentFullFilePath}\""
  echo ""
  ${ffmpegLocation} -i "${tempFile}" -metadata genre="${genre}" "${currentFullFilePath}"
  rm "${tempFile}"

  # udpate author
  if [ -n "${author}" ]; then
    mv "${currentFullFilePath}" "${tempFile}"
    echo ""
    echo "${ffmpegLocation} -i \"${tempFile}\" -metadata author=\"${author}\" \"${currentFullFilePath}\""
    echo ""
    ${ffmpegLocation} -i "${tempFile}" -metadata autho="${author}" "${currentFullFilePath}"
    rm "${tempFile}"
  fi

  # add image
  if [ -n "${image}" ]; then
    mv "${currentFullFilePath}" "${tempFile}"
    echo ""
    echo "${ffmpegLocation} -i \"${tempFile}\" -i \"${image}\" -map_metadata 0 -map 0 -map 1 \"${currentFullFilePath}\""
    echo ""
    ${ffmpegLocation} -i "${tempFile}" -i "${image}" -map_metadata 0 -map 0 -map 1 "${currentFullFilePath}"
    rm "${tempFile}"
  fi

  current=$(( ${current} + ${duration} ))
  counter=$(( ${counter} + 1 ))
done
