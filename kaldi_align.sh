#!/bin/bash

inputdir=$1
datadir=$2/data
resourcedir=$3
langdir=$3/lang
modeldir=$3/AM
aligndir=$2/align
tempdir=$2/temp
outdir=$4

mkdir -p $datadir
mkdir -p $tempdir

cd $resourcedir

. ./cmd.sh
. ./path.sh

for inputfile in $inputdir/*.wav; do
  file_id=$(basename "$inputfile" .wav)
  sox $inputfile -e signed-integer -r 16000 -b 16 $tempdir/${file_id}.wav
  echo "$file_id $tempdir/${file_id}.wav" > $datadir/wav.scp
  echo "$file_id spk0000" > $datadir/utt2spk
  echo "spk0000 $file_id" > $datadir/spk2utt
  text=$(cat $inputdir/${file_id}.txt)
  echo "$file_id $text" > $datadir/text

  fbank=${datadir}
  steps/make_fbank.sh --fbank_config $modeldir/fbank.conf --nj 1 --cmd "run.pl" $fbank $fbank/log $fbank/data || exit 1;
  steps/compute_cmvn_stats.sh $fbank $fbank/log $fbank/data || exit 1;
  steps/nnet/align.sh --nj 1 --cmd "run.pl" $datadir $langdir $modeldir $aligndir || exit 1;
  steps/get_train_ctm.sh $datadir $langdir $aligndir || exit 1;
  cp $aligndir/ctm $outdir/${file_id}.ctm
  scripts/ctm2tg.py $outdir/${file_id}.ctm $tempdir//${file_id}.wav

done

cd -
