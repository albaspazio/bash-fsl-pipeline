# extracts the option name from any version (-- or -)
get_opt1() {
    arg=`echo $1 | sed 's/=.*//'`
    echo $arg
}

# get image filename from -- options
get_imarg1() 
{
    arg=`get_arg1 $1`;
    arg=`$FSLDIR/bin/remove_ext $arg`;
    echo $arg
}

# get arg of image filenames for - options (need to pass both $1 and $2 to this)
get_imarg2() 
{
    arg=`get_arg2 $1 $2`;
    arg=`$FSLDIR/bin/remove_ext $arg`;
    echo $arg
}


# get arg for -- options
get_arg1() {

    if [ X`echo $1 | grep '='` = X ] ; then 
    
			echo "Option $1 requires an argument" 1>&2
			exit 1
			
    else 
    
			arg=`echo $1 | sed 's/.*=//'`
			if [ X$arg = X ] ; then
	    	echo "Option $1 requires an argument" 1>&2
	    	exit 1
			fi
			echo $arg
			
    fi
}


# get arg for - options (need to pass both $1 and $2 to this)
get_arg2() 
{
    if [ X$2 = X ] ; then
			echo "Option $1 requires an argument" 1>&2
			exit 1
    fi
    echo $2
}


run() 
{
  echo $@ >> $LOGFILE 
  $@
  return 0
}


check_run() 
{
	force_overwrite=$1; shift;
	output_file=$1; shift;

	if [ ! -f $output_file -o $force_overwrite -eq 1 ]; then
		echo $@ >> $LOGFILE 
		$@
	fi
}


run_check() 
{
  echo $@ >> $LOGFILE 
  $@
  if [ $? -gt 0 ];	then
  	echo "ERROR detected" >> $LOGFILE
	  return 1  	
  fi
  return 0
}

run_check_exit() 
{
  echo $@ >> $LOGFILE 
  $@
  if [ $? -gt 0 ];	then
  	echo "ERROR detected....exiting" >> $LOGFILE
  	exit
  fi
  return 0
}


run_notexisting_img()
{
	img=$1; shift
	if [ `$FSLDIR/bin/imtest $img` = 0 ]; then
		echo $@ >> $LOGFILE 
		$@
	fi
}

quick_smooth() {
  in=$1
  out=$2
  run $FSLDIR/bin/fslmaths $in -subsamp2 -subsamp2 -subsamp2 -subsamp2 vol16
  run $FSLDIR/bin/flirt -in vol16 -ref $in -out $out -noresampblur -applyxfm -paddingsize 16
  # possibly do a tiny extra smooth to $out here?
  run $FSLDIR/bin/imrm vol16
}

