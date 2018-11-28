## plot eAED
## grep '>' *maker.proteins.fasta | awk '{print $1":"$4}' | perl -ne '@array=split(":", $_); @name=split("-",$array[0]);print $name[1]."\t".$array[2];' > eAED_statistics*
setwd("")

## Frequency function
get_Freq <- function(table2check) {
  
  breaks = seq(0, 1, by=0.02) 
  AED_table <- table(table2check)
  AED_frame <- as.data.frame(AED_table)
  AED.cut = cut(table2check$V1, breaks, right=FALSE) 
  AED.freq = table(AED.cut)
  cumfreq = c(0, cumsum(AED.freq)/sum(AED.freq)) 
  
  return(cumfreq)  
}

## file1
file2check <- "/path/to/file1"
AED1 <- read.table(file2check)
mean_AED1 = mean(AED1$V1)
median_AED1 = median(AED1$V1)
cumfreq_Ret1 <- get_Freq(AED1)

## file2
file2check2 <- "/path/to/file2"
AED2 <- read.table(file2check2)
mean_AED2 = mean(AED2$V1)
median_AED2 = median(AED2$V1)
cumfreq_Ret2 <- get_Freq(AED2)

## file3
#file2check3 <- "/path/to/file3"
#AED3 <- read.table(file2check3)
#mean_AED3 = mean(AED3$V1)
#median_AED3 = median(AED3$V1)
#cumfreq_Ret3 <- get_Freq(AED3)

## file_n
#file2check_n <- "/path/to/file_n"
#AED_n <- read.table(file2check_n)
#mean_AED_n = mean(AED_n$V1)
#median_AED_n = median(AED_n$V1)
#cumfreq_Ret_n <- get_Freq(AED_n)



#################
## set plot
breaks = seq(0, 1, by=0.02) 
plot(breaks,cumfreq_Ret1,ylab="Cummulative Fraction of Annotation", xlab="eAED value", lty=2, type="l",col="deepskyblue", cex.lab=1.5, cex.axis=1.5, cex.main=1.5)
abline(h=0.5, lty=4, col="grey")
legend(
  "bottomright", ## POSITION 
  c("50%", "","file1", "file2"), # puts text in the legend  
    #c("50%", "","file1", "file2", "file3","","file4","file5","file6"), # puts text in the legend 
  lty=c(4,0,2,2),               # gives the legend appropriate symbols (lines)
    #lty=c(4,0,2,2,2,0,1,1,1),               # gives the legend appropriate symbols (lines)
  lwd=c(2), ## width
  cex = 1.3,
  col=c("grey","","deepskyblue","dodgerblue") # gives the legend lines the correct color
  #col=c("grey","","deepskyblue","dodgerblue","darkslateblue","","chartreuse","chartreuse3","darkolivegreen") # gives the legend lines the correct color
)
lines(breaks,cumfreq_Ret2,type="l",lty=2,col="dodgerblue")
#lines(breaks,cumfreq_Ret3,type="l",lty=2,col="darkslateblue")
#lines(breaks,cumfreq_Ret4,type="l",lty=1,col="chartreuse")
#lines(breaks,cumfreq_Ret5,type="l",lty=1,col="chartreuse3")
#lines(breaks,cumfreq_Ret6,type="l",lty=1,col="darkolivegreen")




