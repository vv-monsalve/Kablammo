#!/bin/bash
set -e

glyphsSource="sources/Kablammo.glyphs"

output_path="fonts"
static_output_path="${output_path}/static"
variable_output_path="${output_path}"

rm -rf $output_path
mkdir -p $output_path $static_output_path $variable_output_path 

echo "generate variable font"
VF_full_output_path="${variable_output_path}/Kablammo[MUTA].ttf"
fontmake -g $glyphsSource -o variable --output-path $VF_full_output_path --flatten-components -a

echo "generate static fonts"
fontmake -g $glyphsSource -o otf -i --output-dir $static_output_path/otf -a
fontmake -g $glyphsSource -o ttf -i --output-dir $static_output_path/ttf -a --flatten-components

echo "add stat table"
gftools gen-stat $VF_full_output_path --src sources/scripts/stat.yaml --inplace

echo "misc table fixes"
function fixMiscTables {
  echo "fix-nonhinting"
  gftools fix-nonhinting $1 $1
  gftools fix-hinting $1

  if test -f $1.fix; then
    mv $1.fix $1
  fi

  # echo "fix dsig"
  # gftools fix-dsig -f $1
}
fixMiscTables $VF_full_output_path
for filename in $static_output_path/otf/*.otf; do
  fixMiscTables $filename
done
for filename in $static_output_path/ttf/*.ttf; do
  fixMiscTables $filename
done

rm -rf $static_output_path/otf/*prep-gasp.otf
rm -rf $static_output_path/ttf/*prep-gasp.ttf
rm -rf $variable_output_path/*prep-gasp.ttf


# webfonts
function generateWebfonts {
  for fileFullPath in $1/*$2; do 
    filename=`basename $fileFullPath`
    # echo $filename
    fonttools ttLib.woff2 compress -o $3/${filename/$2/.woff2} $fileFullPath
  done
}
webfonts_path="fonts/web"
webfonts_path_static=$webfonts_path/static
mkdir -p $webfonts_path
mkdir -p $webfonts_path_static

generateWebfonts $variable_output_path .ttf $webfonts_path
generateWebfonts $static_output_path/ttf .ttf $webfonts_path_static


# cleanup 
echo "cleanup"
rm -rf instance_ufo
rm -rf master_ufo

echo "Kablammo Build Finished!"


