args = commandArgs(trailingOnly=TRUE)
purity = as.numeric(args[2])
ploidy = as.numeric(args[1])

if ( is.na(purity) ) {
	warning('ploidy and purity need to be provided')
	} else if( ploidy%%1!=0 ) {
	       	warning('ploidy is not integer')
	} else { sprintf("-m threshold -t=%s",
  paste(round(log2( (1 - purity) + purity * (0:6 + .5) / ploidy ),2),collapse=",")
  )
}
