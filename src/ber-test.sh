# pseudo random pattern

PATTERN=4e1243bd22c66e76c2ba9eddc1f91394
TRANSFORM=$1
if [ "x$AWM_SET" == "x" ]; then
  AWM_SET=small
fi
if [ "x$AWM_SEEDS" == "x" ]; then
  AWM_SEEDS=0
fi

{
  if [ "x$AWM_SET" == "xsmall" ]; then
    ls test/T*
  elif [ "x$AWM_SET" == "xbig" ]; then
    cat test_list
  else
    echo "bad AWM_SET $AWM_SET" >&2
    exit 1
  fi
} | while read i
do
  for SEED in $AWM_SEEDS
  do
    echo $i
    audiowmark add "$i" t.wav $PATTERN $AWM_PARAMS --seed $SEED >/dev/null
    if [ "x$TRANSFORM" == "xmp3" ]; then
      if [ "x$2" == "x" ]; then
        echo "need mp3 bitrate" >&2
        exit 1
      fi
      lame -b $2 t.wav t.mp3 --quiet
      rm t.wav
      ffmpeg -i t.mp3 t.wav -v quiet -nostdin

      # some (low) mpeg quality settings use a lower sample rate
      if [ "x$(soxi -r t.wav)" != "x44100" ]; then
        sox t.wav tr.wav rate 44100
        mv tr.wav t.wav
      fi
    elif [ "x$TRANSFORM" == "xdouble-mp3" ]; then
      if [ "x$2" == "x" ]; then
        echo "need mp3 bitrate" >&2
        exit 1
      fi
      # first mp3 step (fixed bitrate)
      lame -b 128 t.wav t.mp3 --quiet
      rm t.wav
      ffmpeg -i t.mp3 t.wav -v quiet -nostdin

      # second mp3 step
      lame -b $2 t.wav t.mp3 --quiet
      rm t.wav
      ffmpeg -i t.mp3 t.wav -v quiet -nostdin

      # some (low) mpeg quality settings use a lower sample rate
      if [ "x$(soxi -r t.wav)" != "x44100" ]; then
        sox t.wav tr.wav rate 44100
        mv tr.wav t.wav
      fi
    elif [ "x$TRANSFORM" == "xogg" ]; then
      if [ "x$2" == "x" ]; then
        echo "need ogg bitrate" >&2
        exit 1
      fi
      oggenc -b $2 t.wav -o t.ogg --quiet
      oggdec t.ogg -o t.wav --quiet
    elif [ "x$TRANSFORM" == "x" ]; then
      :
    else
      echo "unknown transform $TRANSFORM" >&2
      exit 1
    fi
    # blind decoding
    audiowmark cmp t.wav $PATTERN $AWM_PARAMS --seed $SEED
    # decoding with original
    # audiowmark cmp-delta "$i" t.wav $PATTERN $AWM_PARAMS --seed $SEED
  done
done | grep bit_error_rate | awk 'BEGIN { max_er = er = n = 0 } { er += $2; n++; if ($2 > max_er) max_er = $2;} END { print er / n, max_er; }'
