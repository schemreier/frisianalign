#!/bin/bash

inputdir=$1
scratchdir=$2/data
resourcedir=$3
langdir=$3/lang
modeldir=$3/AM
aligndir=$2/align
tempdir=$2/temp
outdir=$4

echo "Input directory: $inputdir" >&2
echo "Scratch directory: $scratchdir" >&2
echo "Output directory: $outdir" >&2
echo "Resource directory: $resourcedir" >&2

fatalerror() {
    echo "-----------------------------------------------------------------------" >&2
    echo "FATAL ERROR: $*" >&2
    echo "-----------------------------------------------------------------------" >&2
    exit 2
}

mkdir -p $scratchdir
mkdir -p $tempdir

cd $resourcedir

. ./cmd.sh
. ./path.sh

for inputfile in $inputdir/*.wav; do
  file_id=$(basename "$inputfile" .wav)
  sox $inputfile -e signed-integer -r 16000 -b 16 $tempdir/${file_id}.wav || fatalerror "Failure calling sox"
  echo "$file_id $tempdir/${file_id}.wav" > $scratchdir/wav.scp
  echo "$file_id spk0000" > $scratchdir/utt2spk
  echo "spk0000 $file_id" > $scratchdir/spk2utt
  text=$(cat $inputdir/${file_id}.txt)
  echo "$file_id $text" > $scratchdir/text

  fbank=${scratchdir}
  steps/make_fbank.sh --fbank_config $modeldir/fbank.conf --nj 1 --cmd "run.pl" $fbank $fbank/log $fbank/data || fatalerror "Failure running make_fbank.sh"
  steps/compute_cmvn_stats.sh $fbank $fbank/log $fbank/data || fatalerror "Failure running compute_cmvn_stats"
  steps/nnet/align.sh --nj 1 --cmd "run.pl" $scratchdir $langdir $modeldir $aligndir || fatalerror "Failure running nnet/align"
  steps/get_train_ctm.sh $scratchdir $langdir $aligndir || fatalerror "Failure running get_train_ctm"
  cp $aligndir/ctm $outdir/${file_id}.ctm || fatalerror "Copy failed"
  scripts/ctm2tg.py $outdir/${file_id}.ctm $tempdir//${file_id}.wav || fatalerror "Failure running ctm2tg"

done

cd -
