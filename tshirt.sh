#!/bin/bash

#Originally Developed by Fred Weinhaus

coords=""			# coordinates of corners clockwise from top left
region=""			# WxH+X+Y area on background to place overlay image
fit="none"        	# crop or distort the image to fit vertical aspect ratio of region
gravity="center"	# gravity for cropping
vshift=0			# vertical shift of crop region
offset=""       	# additional x,y offsets of region or coordinates
rotate=0			# additional rotation for use only with region
lighting=20			# contrast increase for highlights; integer
blur=1				# blurring/smoothing of displacement image to reduce texture; float
displace=10			# amount of displacement for distortions; integer
sharpen=1			# sharpening of warped overlay image; float
antialias=2			# antialias amount to apply to alpha channel of tshirt image; float
export="no"			# export lighting image, displacement map and other arguments


# set directory for temporary files
tmpdir="/tmp"

# set up functions to report Usage and Usage with Description
PROGNAME=`type $0 | awk '{print $3}'`  # search for executable on path
PROGDIR=`dirname $PROGNAME`            # extract directory of program
PROGNAME=`basename $PROGNAME`          # base name of program
usage1() 
	{
	echo >&2 ""
	echo >&2 "$PROGNAME:" "$@"
	sed >&2 -e '1,/^####/d;  /^###/g;  /^#/!q;  s/^#//;  s/^ //;  4,$p' "$PROGDIR/$PROGNAME"
	}
usage2() 
	{
	echo >&2 ""
	echo >&2 "$PROGNAME:" "$@"
	sed >&2 -e '1,/^####/d;  /^######/g;  /^#/!q;  s/^#*//;  s/^ //;  4,$p' "$PROGDIR/$PROGNAME"
	}


# function to report error messages
errMsg()
	{
	echo ""
	echo $1
	echo ""
	usage1
	exit 1
	}


# function to test for minus at start of value of second part of option 1 or 2
checkMinus()
	{
	test=`echo "$1" | grep -c '^-.*$'`   # returns 1 if match; 0 otherwise
    [ $test -eq 1 ] && errMsg "$errorMsg"
	}

# test for correct number of arguments and get values
if [ $# -eq 0 ]
	then
	# help information
   echo ""
   usage2
   exit 0
elif [ $# -gt 27 ]
	then
	errMsg "--- TOO MANY ARGUMENTS WERE PROVIDED ---"
else
	while [ $# -gt 0 ]
		do
			# get parameter values
			case "$1" in
		     -help|-h)    # help information
					   echo ""
					   usage2
					   exit 0
					   ;;
				-r)    # get region
					   shift  # to get the next parameter
					   # test if parameter starts with minus sign 
					   errorMsg="--- INVALID REGION SPECIFICATION ---"
					   checkMinus "$1"
					   region=`expr "$1" : '\([0-9]*[x][0-9]*[+][0-9]*[+][0-9]*\)'`
					   [ "$blur" = "" ] && errMsg "--- REGION=$region MUST BE NON-NEGATIVE INTEGERS OF THE FORM WxH+X+Y ---"
					   ;;
				-c)    # get coords
					   shift  # to get the next parameter
					   # test if parameter starts with minus sign 
					   errorMsg="--- INVALID COORDS SPECIFICATION ---"
					   checkMinus "$1"
					   coords=`expr "$1" : '\([ ,0-9]*\)'`
					   [ "$coords" = "" ] && errMsg "--- COORDS=$coords MUST BE 4 SPACE SEPARATED INTEGER X,Y PAIRS ---"
					   ;;
		 		-f)    # fit
					   shift  # to get the next parameter
					   # test if parameter starts with minus sign 
					   errorMsg="--- INVALID FIT SPECIFICATION ---"
					   checkMinus "$1"
					   # test gravity values
					   fit="$1"
					   fit=`echo "$1" | tr '[A-Z]' '[a-z]'`
					   case "$fit" in 
					   		none|n) fit="none" ;;
					   		crop|c) fit="crop" ;;
					   		distort|d) fit="distort" ;;
					   		*) errMsg "--- FIT=$fit IS AN INVALID VALUE ---" 
					   	esac
					   ;;
		 		-g)    # gravity
					   shift  # to get the next parameter
					   # test if parameter starts with minus sign 
					   errorMsg="--- INVALID GRAVITY SPECIFICATION ---"
					   checkMinus "$1"
					   # test gravity values
					   gravity="$1"
					   gravity=`echo "$1" | tr '[A-Z]' '[a-z]'`
					   case "$gravity" in 
					   		center|c) gravity=center ;;
					   		north|n) gravity=north ;;
					   		south|s) gravity=south ;;
					   		*) errMsg "--- GRAVITY=$gravity IS AN INVALID VALUE ---" 
					   	esac
					   ;;
				-v)    # get vshift
					   shift  # to get the next parameter
					   # test if parameter starts with minus sign 
					   errorMsg="--- INVALID VSHIFT SPECIFICATION ---"
#					   checkMinus "$1"
					   vshift=`expr "$1" : '\([-]*[0-9]*\)'`
					   [ "$vshift" = "" ] && errMsg "--- VSHIFT=$vshift MUST BE AN INTEGER ---"
					   ;;
				-o)    # get offset
					   shift  # to get the next parameter
					   # test if parameter starts with minus sign 
					   errorMsg="--- INVALID OFFSET SPECIFICATION ---"
#					   checkMinus "$1"
					   offset=`expr "$1" : '\([-]*[0-9]*,[-]*[0-9]*\)'`
					   [ "$offset" = "" ] && errMsg "--- OFFSET=$offset MUST BE ONE INTEGER X,Y PAIR ---"
					   ;;
				-R)    # get rotate
					   shift  # to get the next parameter
					   # test if parameter starts with minus sign 
					   errorMsg="--- INVALID ROTATE SPECIFICATION ---"
#					   checkMinus "$1"
					   rotate=`expr "$1" : '\([-]*[.0-9]*\)'`
					   [ "$rotate" = "" ] && errMsg "--- ROTATE=$rotate MUST BE A NON-NEGATIVE FLOAT ---"
					   test1=`echo "$rotate < -360" | bc`
					   test2=`echo "$rotate > 360" | bc`
					   [ $test1 -eq 1 -o $test2 -eq 1 ] && errMsg "--- ROTATE=$rotate MUST BE AN INTEGER BETWEEN -360 AND 360 ---"
					   ;;
				-b)    # get blur
					   shift  # to get the next parameter
					   # test if parameter starts with minus sign 
					   errorMsg="--- INVALID BLUR SPECIFICATION ---"
					   checkMinus "$1"
					   blur=`expr "$1" : '\([.0-9]*\)'`
					   [ "$blur" = "" ] && errMsg "--- BLUR=$blur MUST BE A NON-NEGATIVE FLOAT ---"
					   ;;
				-s)    # get sharpen
					   shift  # to get the next parameter
					   # test if parameter starts with minus sign 
					   errorMsg="--- INVALID SHARPEN SPECIFICATION ---"
					   checkMinus "$1"
					   sharpen=`expr "$1" : '\([.0-9]*\)'`
					   [ "$sharpen" = "" ] && errMsg "--- SHARPEN=$sharpen MUST BE A NON-NEGATIVE FLOAT ---"
					   ;;
				-b)    # get blur
					   shift  # to get the next parameter
					   # test if parameter starts with minus sign 
					   errorMsg="--- INVALID BLUR SPECIFICATION ---"
					   checkMinus "$1"
					   blur=`expr "$1" : '\([.0-9]*\)'`
					   [ "$blur" = "" ] && errMsg "--- BLUR=$blur MUST BE A NON-NEGATIVE FLOAT ---"
					   ;;
				-a)    # get antialias
					   shift  # to get the next parameter
					   # test if parameter starts with minus sign 
					   errorMsg="--- INVALID ANTIALIAS SPECIFICATION ---"
					   checkMinus "$1"
					   antialias=`expr "$1" : '\([.0-9]*\)'`
					   [ "$antialias" = "" ] && errMsg "--- ANTIALIAS=$antialias MUST BE A NON-NEGATIVE FLOAT ---"
					   ;;
				-l)    # get lighting
					   shift  # to get the next parameter
					   # test if parameter starts with minus sign 
					   errorMsg="--- INVALID LIGHTING SPECIFICATION ---"
					   checkMinus "$1"
					   lighting=`expr "$1" : '\([0-9]*\)'`
					   [ "$lighting" = "" ] && errMsg "--- LIGHTING=$lighting MUST BE A NON-NEGATIVE INTEGER ---"
					   test1=`echo "$lighting < 0" | bc`
					   test2=`echo "$lighting > 30" | bc`
					   [ $test1 -eq 1 -o $test2 -eq 1 ] && errMsg "--- LIGHTING=$lighting MUST BE AN INTEGER BETWEEN 0 AND 30 ---"
					   ;;
				-d)    # get displace
					   shift  # to get the next parameter
					   # test if parameter starts with minus sign 
					   errorMsg="--- INVALID DISPLACE SPECIFICATION ---"
					   checkMinus "$1"
					   displace=`expr "$1" : '\([0-9]*\)'`
					   [ "$displace" = "" ] && errMsg "--- DISPLACE=$displace MUST BE A NON-NEGATIVE INTEGER ---"
					   ;;
				-E)    # get  export
					   export="yes"
					   ;;
			 	-)    # STDIN and end of arguments
					   break
					   ;;
				-*)    # any other - argument
					   errMsg "--- UNKNOWN OPTION ---"
					   ;;
		     	 *)    # end of arguments
					   break
					   ;;
			esac
			shift   # next option
	done
	#
	# get infile and outfile
	infile="$1"
	bgfile="$2"
	outfile="$3"
fi

# test that infile provided
[ "$infile" = "" ] && errMsg "NO OVERLAY FILE SPECIFIED"

# test that bgfile provided
[ "$bgfile" = "" ] && errMsg "NO BACKGROUND (TSHIRT) FILE SPECIFIED"

# test that outfile provided
[ "$outfile" = "" ] && errMsg "NO OUTPUT FILE SPECIFIED"


dir="$tmpdir/TSHIRT.$$"
mkdir "$dir" || {
  echo >&2 "UNABLE TO CREATE WORKING DIR \"$dir\" -- ABORTING"
  exit 10
}
trap "rm -rf $dir;" 0
trap "rm -rf $dir; exit 1" 1 2 3 10 15
trap "rm -rf $dir; exit 1" ERR


# read overlay image
if ! convert -quiet "$infile" +repage $dir/tmpI.mpc; then
	errMsg "--- FILE $infile DOES NOT EXIST OR IS NOT AN ORDINARY FILE, NOT READABLE OR HAS ZERO SIZE ---"
fi	

# read tshirt image
if ! convert -quiet "$bgfile" +repage $dir/tmpT.mpc; then
	errMsg "--- FILE $infile DOES NOT EXIST OR IS NOT AN ORDINARY FILE, NOT READABLE OR HAS ZERO SIZE ---"
fi	


# extract coordinates of subsection of tshirt and bounding box
if [ "$coords" = "" -a "$region" = "" ]; then
	errMsg "--- EITHER COORDINATES OR REGION IS REQUIRED ---"
elif [ "$coords" != "" ]; then
	clist=`echo $coords | sed 's/[, ][, ]*/ /g';`
	test=`echo $clist | wc -w | tr -d " "`
	if [ $test -eq 8 ]; then
		x1=`echo $clist | cut -d\  -f1`
		y1=`echo $clist | cut -d\  -f2`
		x2=`echo $clist | cut -d\  -f3`
		y2=`echo $clist | cut -d\  -f4`
		x3=`echo $clist | cut -d\  -f5`
		y3=`echo $clist | cut -d\  -f6`
		x4=`echo $clist | cut -d\  -f7`
		y4=`echo $clist | cut -d\  -f8`
		
		if [ "$offset" != "" ]; then
			xx=`echo "$offset" | cut -d, -f1`
			yy=`echo "$offset" | cut -d, -f2`
			x1=$((x1+xx))
			y1=$((y1+yy))
			x2=$((x2+xx))
			y2=$((y2+yy))
			x3=$((x3+xx))
			y3=$((y3+yy))
			x4=$((x4+xx))
			y4=$((y4+yy))
		fi
		#echo "$x1,$y1;  $x2,$y2;  $x3,$y3;  $x4,$y4;"
	
		# get bounding box
		minx=`convert xc: -format "%[fx:min(min(min($x1,$x2),$x3),$x4)]" info:`
		miny=`convert xc: -format "%[fx:min(min(min($y1,$y2),$y3),$y4)]" info:`
		maxx=`convert xc: -format "%[fx:max(max(max($x1,$x2),$x3),$x4)]" info:`
		maxy=`convert xc: -format "%[fx:max(max(max($y1,$y2),$y3),$y4)]" info:`
		wd=`convert xc: -format "%[fx:$maxx-$minx+1]" info:`
		ht=`convert xc: -format "%[fx:$maxy-$miny+1]" info:`
		#echo "minx=$minx; miny=$miny; maxx=$maxx; maxy=$maxy; wd=$wd, ht=$ht;"

		# compute offsets, topwidth and correction rotation angle
		xoffset=$x1
		yoffset=$y1
		topwidth=`convert xc: -format "%[fx:hypot(($x2-$x1),($y2-$y1))+1]" info:`
		angle=`convert xc: -format "%[fx:-atan2(($y2-$y1),($x2-$x1))]" info:`
		#echo "xoffset=$xoffset; yoffset=$yoffset; topwidth=$topwidth; angle=$angle;"
	else
		errMsg "--- INCONSISTENT NUMBER OF COORDINATES ---"
	fi
elif [ "$region" != "" ]; then
		region=`echo "$region" | tr -d " " | tr -cs "0-9\n" " "`
		wd=`echo "$region" | cut -d\  -f1`
		ht=`echo "$region" | cut -d\  -f2`
		minx=`echo "$region" | cut -d\  -f3`
		miny=`echo "$region" | cut -d\  -f4`
		#echo "minx=$minx; miny=$miny; wd=$wd, ht=$ht;"
		if [ "$offset" != "" ]; then
			xx=`echo "$offset" | cut -d, -f1`
			yy=`echo "$offset" | cut -d, -f2`
			minx=$((minx+xx))
			miny=$((miny+yy))
		fi
		xoffset=$minx
		yoffset=$miny
		topwidth=$wd
		angle=0
		#echo "xoffset=$xoffset; yoffset=$yoffset; topwidth=$topwidth; angle=$angle;"
		x1=$minx
		y1=$miny
		x2=$((minx+$wd-1))
		y2=$miny
		x3=$((minx+$wd-1))
		y3=$((miny+$ht-1))
		x4=$minx
		y4=$((miny+$ht-1))
		#echo "$x1,$y1;  $x2,$y2;  $x3,$y3;  $x4,$y4;"
		#echo "xoffset=$xoffset; yoffset=$yoffset; topwidth=$topwidth; angle=$angle;"
fi


# get width of overlay image and compute xscale
ww=`convert -ping $dir/tmpI.mpc -format "%w" info:`
hh=`convert -ping $dir/tmpI.mpc -format "%h" info:`
scale=`convert xc: -format "%[fx:($ww-1)/($topwidth-1)]" info:`
#echo "scale=$scale;"


# compute corresponding coordinates in overlay image
if [ "$coords" != "" ]; then
	# subtract offset and unrotate
	xo1=`convert xc: -format "%[fx:round(($x1-$xoffset)*cos($angle)+($y1-$yoffset)*sin($angle))]" info:`
	yo1=`convert xc: -format "%[fx:round(($x1-$xoffset)*sin($angle)+($y1-$yoffset)*cos($angle))]" info:`
	xo2=`convert xc: -format "%[fx:round(($x2-$xoffset)*cos($angle)+($y2-$yoffset)*sin($angle))]" info:`
	yo2=`convert xc: -format "%[fx:round(($x2-$xoffset)*sin($angle)+($y2-$yoffset)*cos($angle))]" info:`
	xo3=`convert xc: -format "%[fx:round(($x3-$xoffset)*cos($angle)+($y3-$yoffset)*sin($angle))]" info:`
	yo3=`convert xc: -format "%[fx:round(($x3-$xoffset)*sin($angle)+($y3-$yoffset)*cos($angle))]" info:`
	xo4=`convert xc: -format "%[fx:round(($x4-$xoffset)*cos($angle)+($y4-$yoffset)*sin($angle))]" info:`
	yo4=`convert xc: -format "%[fx:round(($x4-$xoffset)*sin($angle)+($y4-$yoffset)*cos($angle))]" info:`
	# compute max height
	ho=`convert xc: -format "%[fx:max($yo4-$yo1,$yo3-$yo2)+1]" info:`
	#echo "ho=$ho;"
	xo1=0
	yo1=0
	xo2=$((ww-1))
	yo2=0
	xo3=$((ww-1))
	if [ "$fit" = "distort" ]; then
		yo3=$((hh-1))
	else
		yo3=`convert xc: -format "%[fx:(round($scale*($ho-1)))]" info:`
	fi
	xo4=0
	yo4=$yo3

elif [ "$region" != "" ]; then
	# use input width and scaled height of region for overlay coordinates
	xo1=0
	yo1=0
	xo2=$((ww-1))
	yo2=0
	xo3=$((ww-1))
	if [ "$fit" = "distort" ]; then
		yo3=$((hh-1))
	else
		yo3=`convert xc: -format "%[fx:(round($scale*($ht-1)))]" info:`
	fi
	xo4=0
	yo4=$yo3
fi
#echo "$xo1,$yo1;  $xo2,$yo2;  $xo3,$yo3;  $xo4,$yo4;"
	

# apply rotation about center of scaled down image translated to correct upper left corner
if [ "$rotate" != "0" ]; then
	rotate=`convert xc: -format "%[fx:(pi/180)*$rotate]" info:`
	xcent=`convert xc: -format "%[fx:round(0.5*$topwidth)+$x1]" info:`		
	ycent=`convert xc: -format "%[fx:round(0.5*($hh/$scale)+$y1)]" info:`
#	echo "rotate=$rotate; xcent=$xcent; ycent=$ycent"
	x1=`convert xc: -format "%[fx:round($xcent+($x1-$xcent)*cos($rotate)-($y1-$ycent)*sin($rotate))]" info:`
	y1=`convert xc: -format "%[fx:round($ycent+($x1-$xcent)*sin($rotate)+($y1-$ycent)*cos($rotate))]" info:`
	x2=`convert xc: -format "%[fx:round($xcent+($x2-$xcent)*cos($rotate)-($y2-$ycent)*sin($rotate))]" info:`
	y2=`convert xc: -format "%[fx:round($ycent+($x2-$xcent)*sin($rotate)+($y2-$ycent)*cos($rotate))]" info:`
	x3=`convert xc: -format "%[fx:round($xcent+($x3-$xcent)*cos($rotate)-($y3-$ycent)*sin($rotate))]" info:`
	y3=`convert xc: -format "%[fx:round($ycent+($x3-$xcent)*sin($rotate)+($y3-$ycent)*cos($rotate))]" info:`
	x4=`convert xc: -format "%[fx:round($xcent+($x4-$xcent)*cos($rotate)-($y4-$ycent)*sin($rotate))]" info:`
	y4=`convert xc: -format "%[fx:round($ycent+($x4-$xcent)*sin($rotate)+($y4-$ycent)*cos($rotate))]" info:`
#	echo "$x1,$y1;  $x2,$y2;  $x3,$y3;  $x4,$y4;"
fi


# test if tshirt/bgfile has alpha. If so remove and save for later.
is_alpha=`identify -verbose $dir/tmpT.mpc | grep "Alpha" | head -n 1`
[ "$is_alpha" != "" ] && convert $dir/tmpT.mpc -alpha extract -blur 0x$antialias -level 50x100% $dir/tmpA.mpc

# convert tshirt/bgfile to grayscale and compute amount to add/subtract to change mean to 50%
# use bounding box before any additional rotation as good approximation of region
diff=`convert $dir/tmpT.mpc -alpha off -colorspace gray -write $dir/tmpTG.mpc \
	-crop ${wd}x${ht}+${minx}+${miny} +repage -format "%[fx:100*mean-50]" info:`
#echo "diff=$diff"	


# set up lighting
if [ "$lighting" != "0" ]; then
	cont=`convert xc: -format "%[fx:$lighting/3]" info:`
	lproc="-sigmoidal-contrast $cont,50%"
else
	lproc=""
fi

# set up blurring of the displacement image to soften texture
if [ "$blur" != "0" ]; then
	bproc="-blur 0x$blur"
else
	bproc=""
fi

# convert grayscale tshirt to 50% mean, then to lighting image and displacement image
convert \( $dir/tmpTG.mpc -evaluate subtract $diff% \) \
	\( -clone 0 $lproc -write $dir/tmpL.mpc \) +delete \
	$bproc $dir/tmpD.mpc


if [ "$export" = "yes" ]; then
	# save distortion map
	convert $dir/tmpL.mpc lighting.png
	convert $dir/tmpD.mpc -alpha set displace.png
fi


# set up sharpening of overlay image in perspective
if [ "$sharpen" != "0" ]; then
	sproc="-unsharp 0x$sharpen -clamp"
else
	sproc=""
fi

# set up cropping
cropping=""
if [ "$fit" = "crop" ]; then
	hc=$((yo3+1))
	test=`convert xc: -format "%[fx:($hh>$hc)?1:0]" info:`
	if [ $test -eq 1 ]; then
		cropping="-gravity $gravity -crop ${ww}x${hc}+0+0 +repage"
	fi
fi
#echo "hh=$hh; hc=$hc; cropping=$cropping"	
	
# line2 1-4:  process overlay image to perspective transform with transparent
#             background the size of the tshirt image and sharpen
# lines 5-7:  apply lighting image and make tshirt background from lighting image 
#			  transparent using alpha of previous steps
# lines 8-10: apply displacement image

convert -respect-parenthesis \( $dir/tmpTG.mpc -alpha transparent \) \
	\( $dir/tmpI.mpc $cropping -virtual-pixel none +distort perspective \
	"$xo1,$yo1 $x1,$y1   $xo2,$yo2 $x2,$y2   $xo3,$yo3 $x3,$y3   $xo4,$yo4 $x4,$y4" $sproc \) \
	-background none -layers merge +repage \
	\
	\( -clone 0 -alpha extract \) \
	\( -clone 0 $dir/tmpL.mpc -compose hardlight -composite \) \
	-delete 0 +swap -compose over -alpha off -compose copy_opacity -composite \
	\
	$dir/tmpD.mpc \
	-define compose:args=-$displace,-$displace -compose displace -composite \
	$dir/tmpITD.mpc


# composite distorted overlay onto tshirt
if [ "$is_alpha" != "" ]; then
	convert $dir/tmpT.mpc $dir/tmpITD.mpc -compose over -composite \
		$dir/tmpA.mpc -alpha off -compose copy_opacity -composite "$outfile"
else
	convert $dir/tmpT.mpc $dir/tmpITD.mpc -compose over -composite "$outfile"
fi

if [ "$export" = "yes" ]; then
# show arguments
echo "coordinates=\"$xo1,$yo1 $x1,$y1 $xo2,$yo2 $x2,$y2 $xo3,$yo3 $x3,$y3 $xo4,$yo4 $x4,$y4\""
echo "sharpen=\"$sharpen\""
echo "displace=\"$displace\""
fi

exit 0

