#!/bin/bash

factorial()
{
	FACT_NUM=$1
	num_fact=1
	
	if [ $FACT_NUM -gt 0 ]; then for((i=$FACT_NUM;i>=1;i--)); do num_fact=`expr $num_fact \* $i`; done; fi; 
	
	echo $num_fact
}

num_combination()
{
	#  from_n!/(from_n-elem_k)!elem_k!

	from_n=$1
	elem_k=$2
	
	
}



factorial 5
