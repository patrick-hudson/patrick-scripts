#!/bin/bash
PHPSESSID=
RNLBSERVERID=
DOWNLOAD_DIR=""
POSTS_FOLDER=""
RTORRENT_DIR=""
RTORRENT_WATCH_DIR=""
JERKING_COOKIE=""
JERKING_TOKEN=""
ALBUM_ID=""
function usage () {
  echo " "
  echo "usage is "
  echo " <script> -n <video name>"
  exit
}
while getopts "n:c:f:q:ivpV" flag; do
  case "$flag" in
        n) ID="$OPTARG" ;;
        c) CS_START_TIME="$OPTARG" ;;
        f) CS_DURATION="$OPTARG" ;;
        q) FILE_QUALITY="$OPTARG" ;;
        v) V=true ;;
        i) I=true ;;
        p) P=true ;;
        V) VERBOSE='true' ;;
        \?) usage ; exit_error "Invalid option" ;;
  esac
done
function _debug () {
  if [ "$VERBOSE" = "true" ]; then
    echo $@
  fi
}
testJerkAuth() {
  ALBUMREQUEST=$(curl -s -H "Cookie: PHPSESSID=${JERKING_COOKIE}" -H 'Content-Type: multipart/form-data;' -F "action=list" -F "auth_token=${JERKING_TOKEN}" -F "list=albums" -F "albumid=${ALBUMID}" https://jerking.empornium.ph/json)
  ALBUMRESPONSE=$(echo "${ALBUMREQUEST}" | jq -r '.status_code')
  if [ "$ALBUMRESPONSE" != "200" ]; then
    echo "Auth Failed, please check the token details"
    exit 1
  fi
}
makeGif() {
  #Make a gif
  VIDEO_DIR=$1
  VIDEO_FILE=$2
  VIDEO_PATH="$VIDEO_DIR/$VIDEO_FILE"
  _debug "Creating Gif"
  mkdir "$VIDEO_DIR/grabs"
  lenght=$(mediainfo --Inform="General;%Duration%" "${VIDEO_PATH}")
  let lenght=$lenght/1000
  for ((n=1;n<11;n++)); do
  ffmpeg -v error -ss $(( lenght * n / 11 )) -i "${VIDEO_PATH}" -frames:v 1 -vf "scale=320:-1" "$VIDEO_DIR/grabs/"out$n.png
  done
  ffmpeg -v error -i "$VIDEO_DIR/grabs/"out%1d.png -vf palettegen "$VIDEO_DIR/grabs/"palette.png
  ffmpeg -v error -r 1 -i "$VIDEO_DIR/grabs/"out%1d.png -i "$VIDEO_DIR/grabs/"palette.png -filter_complex paletteuse=floyd_steinberg -loop 0 "$VIDEO_DIR/grabs/${VIDEO_FILE}".gif
  _debug "Finish Gif"
}
uploadImageJerk() {
  IMAGE_PATH=$1
  UPLOAD=$(curl -s -H "Cookie: PHPSESSID=$JERKING_COOKIE" -H 'Content-Type: multipart/form-data;' -F "action=upload" -F "auth_token=$JERKING_TOKEN" -F "type=file" -F "source=@$IMAGE_PATH" https://jerking.empornium.ph/json)
}
uploadImageFapping() {
  URL=$1
  ENCURL=$(python -c "import sys, urllib as ul; print ul.quote_plus(\"${URL}\")")
  UPLOADFAPPING=$(curl 'https://fapping.empornium.sx/upload.php' --data "url=${ENCURL}&resize=" --compressed|jq -r '.[]')
}

mediaInfo() {
  VIDEO_DIR=$1
  VIDEO_FILE=$2
  VIDEO_PATH="$VIDEO_DIR/$VIDEO_FILE"
  DURATION=$(mediainfo --Inform="General;%Duration/String2%" "${VIDEO_PATH}")
  FILESIZE=$(mediainfo --Inform="General;%FileSize/String2%" "${VIDEO_PATH}")
  CODEC=$(mediainfo --Inform="Video;%Codec%" "${VIDEO_PATH}")
  FORMAT=$(mediainfo --Inform="General;%Format%" "${VIDEO_PATH}")
  BITRATE=$(mediainfo --Inform="Video;%BitRate/String%" "${VIDEO_PATH}")
  WIDTH=$(mediainfo --Inform="Video;%Width%" "${VIDEO_PATH}")
  HEIGHT=$(mediainfo --Inform="Video;%Height%" "${VIDEO_PATH}")
  _debug "$DURATION - $FILESIZE - $CODEC - $FORMAT - $BITRATE - $WIDTH x $HEIGHT"
}

cumShot() {
  VIDEO_DIR=$1
  VIDEO_FILE=$2
  VIDEO_PATH="$VIDEO_DIR/$VIDEO_FILE"
  SECONDS=$(echo ${CS_START_TIME} | awk -F: '{ print ($1 * 60) + $2 }')
  ffmpeg -y -ss $SECONDS -t $CS_DURATION -i "$VIDEO_PATH" -vf "fps=20,scale=320:-1:flags=lanczos,palettegen" "$VIDEO_DIR/palette.png"
  ffmpeg -ss $SECONDS -t $CS_DURATION -i "$VIDEO_PATH" -i "$VIDEO_DIR/palette.png" -filter_complex "fps=20,scale=320:-1:flags=lanczos[x];[x][1:v]paletteuse" "$VIDEO_PATH.gif"
  rm "$VIDEO_DIR/palette.png"
  gifsicle -O3 "$VIDEO_PATH.gif" --lossy=150 -o "$VIDEO_PATH.opt.gif"
  uploadImageJerk "$VIDEO_PATH.opt.gif"
  CUMSHOTURL=$(echo "${UPLOAD}" | jq -r '. | {image: .image.url} | .[]')
  rm "$VIDEO_PATH.opt.gif"
  rm "$VIDEO_PATH.gif"
}

generatePost() {
  VIDEO_DIR=$1
  VIDEO_FILE=$2
  mkdir "$VIDEO_DIR/screens"
  /usr/local/bin/mtn -O "$VIDEO_DIR/screens" -o _three.jpg -i -t -w 1920 -c 1 -r 3 -f /usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf "$VIDEO_DIR/$VIDEO_FILE"
  /usr/local/bin/mtn -O "$VIDEO_DIR/screens" -o _ten.jpg -i -t -w 1920 -c 4 -r 10 -f /usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf "$VIDEO_DIR/$VIDEO_FILE"
  makeGif "$VIDEO_DIR" "$VIDEO_FILE"
  uploadImageJerk "$VIDEO_DIR/grabs/${VIDEO_FILE}".gif
  _debug "$VIDEO_DIR/grabs/${VIDEO_FILE}".gif
  GIFCOVER=$(echo "${UPLOAD}" | jq -r '. | {image: .image.url} | .[]')
  if [ -d "$VIDEO_DIR/grabs/" ]; then
    _debug "removing grabs folder"
    rm -r "$VIDEO_DIR/grabs/"
  fi
  mediaInfo "$VIDEO_DIR" "$VIDEO_FILE"
  cumShot "$VIDEO_DIR" "$VIDEO_FILE"
  IMAGEBASE=$(echo "$VIDEO_FILE"|sed 's|\.mp4||g')
  _debug "Uploading screens to jerker"
  uploadImageJerk "$VIDEO_DIR/screens/${IMAGEBASE}_three.jpg"
  THREEURL=$(echo "${UPLOAD}" | jq -r '. | {image: .image.url} | .[]')
  uploadImageJerk "$VIDEO_DIR/screens/${IMAGEBASE}_ten.jpg"
  TENURL=$(echo "${UPLOAD}" | jq -r '. | {image: .image.url} | .[]')
  TENMDURL=$(echo "${UPLOAD}" | jq -r '. | {image: .image.medium.url} | .[]')
  uploadImageFapping $THREEURL
  BACKUPTHREE=$UPLOADFAPPING
  uploadImageFapping $TENURL
  BACKUPTEN=$UPLOADFAPPING
  BACKUPTHREE=$(curl https://fapping.empornium.sx/image/${BACKUPTHREE} | grep -o '\[img\].*\[\/img]' | head -n1)
  BACKUPTEN=$(curl https://fapping.empornium.sx/image/${BACKUPTEN} | grep -o '\[img\].*\[\/img]' | head -n1)
  _debug "$THREEURL - $TENMDURL - $TENURL - $CUMSHOTURL - $GIFCOVER - $BACKUPTHREE - $BACKUPTEN"
  VIDEO_TITLE=$(echo "${VIDEO_DIR}" | sed "s|${DOWNLOAD_DIR}/||g")
cat<<EOF > ${POSTS_FOLDER}/"$VIDEO_TITLE".txt
${IMAGEBASE}

${SITENAME}.com brazzers.com ${HEIGHT}p ${FEATURES_TAG} ${TAGS}

${GIFCOVER}

[bg=https://jerking.empornium.ph/images/2017/10/11/seamless_paper_texture.png,left][bg=#00000000,100%]
[center]
[bg=https://jerking.empornium.ph/images/2017/10/11/dark-triangles.png,95%]
[table=95%,nball,nopad][tr]
[td][url=#desc][size=4][font=Arial][color=#FFFFFF][b]Description[/b][/color][/font][/size][/url][/td]
[td][url=#thumb][size=4][font=Arial][color=#FFFFFF][b]Thumbnails[/b][/color][/font][/size][/url][/td]
[td][url=#comments][size=4][font=Arial][color=#FFFFFF][b]Comments[/b][/color][/font][/size][/url][/td]
[/tr][/table]
[/bg]

[table=95%,nball,nopad][tr]
[td][align=center][img]https://jerking.empornium.ph/images/2017/10/17/zTWJH.png[/img][/align][/td]
[/tr]
[tr]
[td][align=center][img]https://jerking.empornium.ph/images/2017/10/17/${SITENAME}.png[/img][/align][/td]
[/tr]
[/table]


[bg=https://jerking.empornium.ph/images/2017/10/11/dark-triangles.png,95%]
[table=95%,nball,nopad][tr]
[td][size=4][font=Arial][color=#FFFFFF][b]${VIDEO_TITLE}[/b][/color][/font][/size][/td]
[/tr]
[/table]
[/bg]

[table=95%,nball,nopad]
[tr][td]
[img]${THREEURL}[/img]
[/td][/tr]
[/table]

[anchor=desc][/anchor]

[bg=https://jerking.empornium.ph/images/2017/10/11/dark-triangles.png,95%][size=10][font=Arial][color=#e6e6e6][b]Description[/b][/color][/font][/size][/bg]

[table=https://jerking.empornium.ph/images/2017/10/11/dark-triangles.png,95%,nball]
[tr]
[td][size=3][font=Arial][color=#e6e6e6]

${DESCRIPTION}

[/color][/font][/size][/td][/tr]
[/table]

[bg=https://jerking.empornium.ph/images/2017/10/11/dark-triangles.png,95%][size=10][font=Arial][color=#e6e6e6][b]Cumshot[/b][/color][/font][/size][/bg]

[img]${CUMSHOTURL}[/img]

[anchor=thumb][/anchor]
[bg=https://jerking.empornium.ph/images/2017/10/11/dark-triangles.png,95%][size=10][font=Arial][color=#e6e6e6][b]Thumbnails[/b][/color][/font][/size][/bg]

[url=${TENURL}][img]${TENMDURL}[/img][/url]

[table=https://jerking.empornium.ph/images/2017/10/11/dark-triangles.png,95%,nball,nopad]
[tr]
[td][size=10][font=Arial][color=#e6e6e6][b]File information[/b][/color][/font][/size][/td]
[/tr]
[/table]
[table=95%,nball]
[tr]
[td][size=3][font=Arial][color=#e6e6e6][code]Format: ${FORMAT}
Resolution: ${WIDTH}x${HEIGHT}
File Size: ${FILESIZE}
Duration: ${DURATION}
Overal bit rate: ${BITRATE}
[/code][/color][/font][/size][/td]
[/tr]
[/table]

[bg=https://jerking.empornium.ph/images/2017/10/11/dark-triangles.png,95%]
[table=95%,nball,nopad][tr]
[td][size=3][font=Arial][color=#e6e6e6][b][spoiler=Backup Screens and Thumbnails]
${BACKUPTHREE}
${BACKUPTEN}
[/spoiler][/b][/color][/font][/size][/td]
[/tr]
[/table]
[/bg]
[size=3][font=Courier New][color=#000000][b][img]https://fapping.empornium.sx/images/2015/09/04/1singlecoinbyjoshr691-d5dmvpn.gif[/img]If you are feeling generous I will always appreciate credits![img]https://fapping.empornium.sx/images/2015/09/04/1singlecoinbyjoshr691-d5dmvpn.gif[/img][/b][/color][/font][/size]

[/center]
[/bg][/bg]
EOF

}
buildMetaData() {
  if [ "$V" = "true" ] || [ "$I" = "true" ]; then
    _debug "Checking if $DOWNLOAD_DIR exists"
      if [ ! -d $DOWNLOAD_DIR ]; then
        _debug "Download Directory - $DOWNLOAD_DIR does NOT exist ... Creating"
        mkdir $DOWNLOAD_DIR
      else
        _debug "Download Directory exists"
      fi
  fi
  VIDEOPAGEDATA=$(curl -s --compressed "https://ma.brazzers.com/scene/view/$ID/" -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecurets: 1' -H "Cookie: PHPSESSID=$PHPSESSID; RNLBSERVERID=$RNLBSERVERID;" | tr '\n' ' ' | tr -s ' ')
  TITLE=$(echo ${VIDEOPAGEDATA} | grep -o '<title>.*</title>' | sed 's|<title>\(.*\)</title>|\1|g' | sed 's/\(.*\)\s-\s.*/\1/')
  DESCRIPTION=$(echo ${VIDEOPAGEDATA}| grep -o '<div class="description-tags-placeholder">.*</div> <h1>' | grep -o '<p>.*</p>' | sed -e '1s/.*<p>//' -e '$s/<\/p>.*//')
  TAGS=$(echo ${VIDEOPAGEDATA}| grep '<div class="description-tags-placeholder">.*</div> <h1>' | grep -o '<script> var timelineData = .*playerThumbs' | sed 's|<script> var timelineData = \(.*\),"videoLength".*, playerThumbs|\1}|g' | jq -r '.[]|.tag_name' | sed "s/\s/./g" | sed -e "s/(//g" -e "s/)//g"| tr '\n' ' ')
  SITENAME=$(echo ${VIDEOPAGEDATA} |grep -o '<div class="collection-aside">.*</div> <h1>' | grep -o '<span class="label-text">.*</span> </a> <div class="like-actions-container clearfix">' | sed 's|<span class="label-text">\(.*\)</span>.*|\1|g')
  SITENAME=$(echo ${SITENAME} | sed 's| ||g')
  VDATE=$(echo ${VIDEOPAGEDATA}| grep -o '<div class="scene-description-placeholder clearfix"> <time>.*</time> <div class="video-description-btn-placeholder">' | grep -o '<time>.*</time>' | sed 's|<time>\(.*\)</time>|\1|g')
  FDATE=$(date -d "${VDATE}" +%Y-%m-%d)
  FEATURES=$(echo ${VIDEOPAGEDATA} | grep -o '<header class="clearfix ">.*<h2>.*</h2> </header>' | grep -o '<h2>.*</h2> </header> <nav class="scene-nav-tab clearfix ">' |grep -o '<a href=.*>.*</a>'|awk '{gsub("<[^>]*>", "")}1' |xargs | sed 's|&nbsp;| |g' | sed 's|&amp;|\&|g'| rev | cut -d '&' -f2- | rev | sed 's/ *$//')
  FEATURES_TAG=$(echo ${VIDEOPAGEDATA} | grep -o '<header class="clearfix ">.*<h2>.*</h2> </header>' | grep -o '<h2>.*</h2> </header> <nav class="scene-nav-tab clearfix ">' |grep -o '<a href=.*>.*</a>'|awk '{gsub("<[^>]*>", "")}1' |xargs | sed 's|&nbsp;| |g' | sed 's|&amp;||g' | sed 's|  |,|g' | sed 's| |.|g' | sed 's|,| |g')
  _debug "[$SITENAME] - $TITLE - Description: $DESCRIPTION - Tags: $TAGS"
  DIRNAME="$DOWNLOAD_DIR/[$SITENAME] - $FEATURES - $FDATE"
}
generateTorrent() {
  mktorrent -o "${POSTS_FOLDER}/${VIDEO_FILE}.torrent" -p -a "" "${VIDEO_DIR}"
  cp "${POSTS_FOLDER}/${VIDEO_FILE}.torrent" "${RTORRENT_WATCH_DIR}"
}
downloadVideo() {
  DOWNLOADVIDEOURL_1080p=$(curl -s --compressed "https://ma.brazzers.com/download/${ID}/2/mp4_1080_12000/" -s -L -I -o /dev/null -w '%{url_effective}' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecurets: 1' -H "Cookie: PHPSESSID=$PHPSESSID; RNLBSERVERID=$RNLBSERVERID;")
  DOWNLOADVIDEOURL_720p=$(curl -s --compressed "https://ma.brazzers.com/download/${ID}/2/mp4_720_8000/" -s -L -I -o /dev/null -w '%{url_effective}' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecurets: 1' -H "Cookie: PHPSESSID=$PHPSESSID; RNLBSERVERID=$RNLBSERVERID;")
  DOWNLOADVIDEOURL_480p=$(curl -s --compressed "https://ma.brazzers.com/download/${ID}/2/mp4_480_2000/" -s -L -I -o /dev/null -w '%{url_effective}' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecurets: 1' -H "Cookie: PHPSESSID=$PHPSESSID; RNLBSERVERID=$RNLBSERVERID;")
  buildMetaData
  DIRNAME_1080p="$DIRNAME [1080p]"
  DIRNAME_720p="$DIRNAME [720p]"
  DIRNAME_480p="$DIRNAME [480p]"
  DLFILE1080_NAME=$(echo ${DOWNLOADVIDEOURL_1080p} | sed 's|.*/hd/\(.*\).mp4.*|\1|g')
  DLFILE720_NAME=$(echo ${DOWNLOADVIDEOURL_720p} | sed 's|.*/hd/\(.*\).mp4.*|\1|g')
  DLFILE480_NAME=$(echo ${DOWNLOADVIDEOURL_480p} | sed 's|.*/hd/\(.*\).mp4.*|\1|g')
  FINAL480="$SITENAME - $FEATURES - $FDATE - 480p.mp4"
  FINAL720="$SITENAME - $FEATURES - $FDATE - 720p.mp4"
  FINAL1080="$SITENAME - $FEATURES - $FDATE - 1080p.mp4"
  if [[ $FILE_QUALITY == "" ]]; then
    #_debug "Checking to see if 720p and 1080p folders exist"
    #if [ ! -d "$DIRNAME_1080p" ]; then
    # _debug "Download Directory $DIRNAME_1080p - does NOT exist ... Creating"
    #  mkdir "$DIRNAME_1080p"
    #else
    #  _debug "Download Directory $DIRNAME_1080p - does exist ... Continuing"
    #fi
    #if [ ! -d "$DIRNAME_720p" ]; then
    #  _debug "Download Directory $DIRNAME_720p - does NOT exist ... Creating"
    #  mkdir "$DIRNAME_720p"
    #else
    #  _debug "Download Directory $DIRNAME_720p - does exist ... Continuing"
    #fi
    #if [ ! -d "$DIRNAME_480p" ]; then
    #  _debug "Download Directory $DIRNAME_480p - does NOT exist ... Creating"
    #  mkdir "$DIRNAME_480p"
    #else
    #  _debug "Download Directory $DIRNAME_480p - does exist ... Continuing"
    #fi
    _debug "Downloading 480p video - Name: $DIRNAME_480p/$FINAL480"
    #curl -o "$DIRNAME_480p/$FINAL480" $DOWNLOADVIDEOURL_480p
    #generatePost "$DIRNAME_480p" "$FINAL480"
    _debug "Downloading 720p video - Name: $DIRNAME_720p/$FINAL720"
    #curl -o "$DIRNAME_720p/$FINAL720" $DOWNLOADVIDEOURL_720p
    _debug "Downloading 1080p video - Name: $DIRNAME_1080p/$FINAL1080"
    #curl -o "$DIRNAME_1080p/$FINAL1080" $DOWNLOADVIDEOURL_1080p
  else
    if [[ $FILE_QUALITY == "480p" ]]; then
      if [ ! -d "$DIRNAME_480p" ]; then
        _debug "Download Directory $DIRNAME_480p - does NOT exist ... Creating"
        mkdir "$DIRNAME_480p"
      else
        _debug "Download Directory $DIRNAME_480p - does exist ... Continuing"
      fi
      _debug "Downloading 480p video - Name: $DIRNAME_480p/$FINAL480"
      curl -o "$DIRNAME_480p/$FINAL480" $DOWNLOADVIDEOURL_480p
      generatePost "$DIRNAME_480p" "$FINAL480"
      cp -r "$DIRNAME_480p" "$RTORRENT_DIR"
      generateTorrent
    elif [[ $FILE_QUALITY == "720p" ]]; then
      if [ ! -d "$DIRNAME_720p" ]; then
        _debug "Download Directory $DIRNAME_720p - does NOT exist ... Creating"
        mkdir "$DIRNAME_720p"
      else
        _debug "Download Directory $DIRNAME_720p - does exist ... Continuing"
      fi
      _debug "Downloading 720p video - Name: $DIRNAME_720p/$FINAL720"
      curl -o "$DIRNAME_720p/$FINAL720" $DOWNLOADVIDEOURL_720p
      generatePost "$DIRNAME_720p" "$FINAL720"
      cp -r "$DIRNAME_720p" "$RTORRENT_DIR"
      generateTorrent
    elif [[ $FILE_QUALITY == "1080p" ]]; then
      if [ ! -d "$DIRNAME_1080p" ]; then
       _debug "Download Directory $DIRNAME_1080p - does NOT exist ... Creating"
        mkdir "$DIRNAME_1080p"
      else
        _debug "Download Directory $DIRNAME_1080p - does exist ... Continuing"
      fi
      _debug "Downloading 1080p video - Name: $DIRNAME_1080p/$FINAL1080"
      curl -o "$DIRNAME_1080p/$FINAL1080" $DOWNLOADVIDEOURL_1080p
      generatePost "$DIRNAME_1080p" "$FINAL1080"
      cp -r "$DIRNAME_1080p" "$RTORRENT_DIR"
      generateTorrent
    else
      echo "Unknown quality"
      exit 1
    fi
  fi
}

downloadImages() {
  IMAGEPAGEDATA=$(curl -s --compressed "https://ma.brazzers.com/scene/hqpics/$ID/" -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecurets: 1' -H "Cookie: PHPSESSID=$PHPSESSID; RNLBSERVERID=$RNLBSERVERID;" | tr '\n' ' ' | tr -s ' ')
  buildMetaData
  DOWNLOADIMAGEURL=$(echo ${IMAGEPAGEDATA} | grep -o '<menu> <ul> <li>.*</li> <li> <div class="counter">' | awk '/<a href/ {print $5}' | sed 's|href="\(.*\)"|\1|')
  DOWNLOADIMAGEURL="https:$DOWNLOADIMAGEURL"
  DIRNAME_IMAGES="$DIRNAME [Images]"
  _debug "Checking to see if image folder exists"
  if [ ! -d "$DIRNAME_IMAGES" ]; then
    _debug "Download Directory $DIRNAME_IMAGES - does NOT exist ... Creating"
    mkdir "$DIRNAME_IMAGES"
  else
    _debug "Download Directory $DIRNAME_IMAGES - does exist ... Continuing"
  fi
  _debug "Downloading Images"
  curl -o "$DIRNAME_IMAGES/images.zip" $DOWNLOADIMAGEURL
  _debug "$DOWNLOADIMAGEURL"

}
testJerkAuth
if [ "$P" = "true" ]; then
  buildMetaData
  generatePost
fi
if [ "$V" = "true" ]; then
  downloadVideo
fi
if [ "$I" = "true" ]; then
  downloadImages
fi
