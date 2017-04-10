#!/bin/bash

KALDI_main=??????
KALDI_root=$KALDI_main/egs/wsj/s5
. $KALDI_root/path.sh
. $KALDI_root/utils/parse_options.sh

inputdir=$1
datadir=$2/data
langdir=$3/lang
modeldir=$3/AM
aligndir=$2/align
outdir=$4
mkdir -p $datadir

for inputfile in $inputdir/*.wav; do
  file_id=$(basename "$inputfile" .wav)
  echo "$file_id $inputfile" > $datadir/wav.scp
  echo "$file_id spk0000" > $datadir/utt2spk
  echo "spk0000 $file_id" > $datadir/spk2utt
  text=$(cat $inputdir/${file_id}.txt)
  echo "$file_id $text" > $datadir/text
  
  fbank=${datadir}
  $KALDI_root/steps/make_fbank.sh --nj 1 --cmd "run.pl" $fbank $fbank/log $fbank/data || exit 1;
  $KALDI_root/steps/compute_cmvn_stats.sh $fbank $fbank/log $fbank/data || exit 1;
  $KALDI_root/steps/nnet/align.sh --nj 1 --cmd "run.pl" $datadir $langdir $modeldir $aligndir || exit 1;
  $KALDI_root/steps/get_train_ctm.sh $datadir $langdir $aligndir || exit 1;
  cp $aligndir/ctm $outdir/${file_id}.ctm
done
