#!/bin/bash
export PATH="/home/eng/rsiverd/bin:$PATH"
source /home/eng/venv_labcam/bin/activate
src_dir="images"
dst_dir="fixed"
mkdir -p $dst_dir
for image in $(ls $src_dir/labcam*.fits); do
   echo "image: $image"
   ibase="${image##*/}"
   isave="$dst_dir/$ibase"
   #echo "ibase: $ibase"
   echo "isave: $isave"
   if [ ! -f $isave ]; then
      nres-labstitch $image -r4096 -o $isave
   fi
   echo
done
