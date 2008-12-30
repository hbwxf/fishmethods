
#data<-read.csv("P:/Rwork/Book/Kimura.csv",header=T)

vblrt<-function(len=NULL,age=NULL,group=NULL,error=1,select=1,Linf=NULL,K=NULL,t0=NULL){
   if(is.null(len)) 
         stop ("len is missing") 
   if(is.null(age)) 
         stop ("age is missing") 
   if(is.null(group)) 
         stop ("group is missing.") 
   if(length(age)!=length(len)) stop ("Vectors of different lengths")
   if(nlevels(as.factor(group))>2) stop("Only two groups allowed in data")
   if(select==2 & (is.null(Linf)|is.null(K)|is.null(t0))) stop("User-specified values of Linf, K, and t0 are required")
      cat<-as.integer(as.factor(group))-1 
     	x<-as.data.frame(cbind(len,age,cat))
      x<-x[!is.na(x$len) & !is.na(x$age) & !is.na(x$cat),]

  if(select==1){ 
      m1xt<-NULL;m2xt<-NULL;mbxt<-NULL
      g1<-aggregate(x$len,list(x$cat,trunc(x$age)),mean)
      m1<-g1[g1[,1]==0,];m2<-g1[g1[,1]==1,]
      m1t<-m1[,c(2:3)];m1t[,1]<-m1t[,1]-1; m2t<-m2[,c(2:3)];m2t[,1]<-m2t[,1]-1
      m1xt<-merge(m1,m1t,by.x=c("Group.2"),by.y=c("Group.2"))
      out1<-lm(m1xt[,4]~m1xt[,3])
      K1<-abs(log(coef(out1)[2]));L1<--coef(out1)[1]/(coef(out1)[2]-1)
      dx1<-as.data.frame(cbind(L1-m1$x,m1[,2]));dx1<-dx1[dx1[,1]>0,]
      t01<-(coef(lm(log(dx1[,1])~dx1[,2]))[1]-log(L1))/K1

      m2xt<-merge(m2,m2t,by.x=c("Group.2"),by.y=c("Group.2"))
      out2<-lm(m2xt[,4]~m2xt[,3])
 	K2<-abs(log(coef(out2)[2]));L2<--coef(out2)[1]/(coef(out2)[2]-1)
      dx2<-as.data.frame(cbind(L2-m2$x,m2[,2]));dx2<-dx2[dx2[,1]>0,]
      t02<-(coef(lm(log(dx2[,1])~dx2[,2]))[1]-log(L2))/K2

      g2<-aggregate(x$len,list(round(x$age,0)),mean)
      mbt<-g2;mbt[,1]<-mbt[,1]-1
      mbxt<-merge(g2,mbt,by.x=c("Group.1"),by.y=c("Group.1"))
      outboth<-lm(mbxt[,3]~mbxt[,2])
      Kboth<-abs(log(coef(outboth)[2]));Lboth<--coef(outboth)[1]/(coef(outboth)[2]-1)
 	dxb<-as.data.frame(cbind(Lboth-g2$x,g2[,1]));dxb<-dxb[dxb[,1]>0,]
      t0b<-(coef(lm(log(dxb[,1])~dxb[,2]))[1]-log(Lboth))/Kboth
      Ld<-L2-L1;Kd<-K2-K1;td<-t02-t01
    }
    if(select==2){
         L1<-L2<-Lboth<-Linf; K1<-K2<-Kboth<-K;t01<-t02<-t0b<-t0
      }
      if(error==1) x$wgt<-1
 	if(error==2){
         x<-aggregate(x$len,list(x$cat,x$age),mean)
         names(x)<-c("cat","age","len")
         x$wgt<-1
        }
      if(error==3){
         d4<-merge(aggregate(x$len,list(x$cat,x$age),mean),
           aggregate(x$len,list(x$cat,x$age),var),by.y=c("Group.1","Group.2"),
           by.x=c("Group.1","Group.2"))
	   d4<-merge(d4,aggregate(x$len,list(x$cat,x$age),length),by.y=c("Group.1","Group.2"),by.x=c("Group.1","Group.2"))
         names(d4)<-c("cat","age","len","s2","n")
         x<-d4
         x$wgt<-x$n/x$s2 
         if(any(is.na(x$wgt))) stop("At least one age has a single length observation. Need at least two observations to calculate variance." )
        }
  	 Ho<-nls(len~(Linf+ls*cat)*(1-exp(-(K+ks*cat)*(age-(t0+ts*cat)))),data=x,       
        	 weights=wgt,start=list(Linf=L1,ls=Ld,K=K1,ks=Kd,t0=t01,ts=td),
             control=list(maxiter = 1000000))
             resid0<-residuals(Ho)
 	 H1<-nls(len~Linf*(1-exp(-(K+ks*cat)*(age-(t0+ts*cat)))),data=x,        
		weights=wgt,start=list(Linf=Lboth,K=K1,ks=Kd,t0=t01,ts=td),
            control=list(maxiter = 1000000))
	    resid1<-residuals(H1)  
 	 H2<-nls(len~(Linf+ls*cat)*(1-exp(-K*(age-(t0+ts*cat)))),data=x,       
		weights=wgt,start=list(Linf=L1,ls=Ld,K=Kboth,t0=t01,ts=td),
             control=list(maxiter = 1000000))
         resid2<-residuals(H2)
    	 H3<-nls(len~(Linf+ls*cat)*(1-exp(-(K+ks*cat)*(age-t0))),data=x,       
         	weights=wgt,start=list(Linf=L1,ls=Ld,K=K1,ks=Kd,t0=t0b),
             control=list(maxiter = 1000000))
         resid3<-residuals(H3)
  	 H4<-nls(len~Linf*(1-exp(-K*(age-t0))),data=x ,      
       	  weights=wgt,start=list(Linf=Lboth,K=Kboth,t0=t0b),
              control=list(maxiter = 1000000))
         resid4<-residuals(H4)
  	 RSS<-c(sum(residuals(Ho)^2),sum(residuals(H1)^2),sum(residuals(H2)^2),
             sum(residuals(H3)^2),sum(residuals(H4)^2))

 	 N<-length(residuals(Ho))
  	 X<-round(c(-N*log(RSS[1]/RSS[2]),-N*log(RSS[1]/RSS[3]),-N*log(RSS[1]/RSS[4]),
             -N*log(RSS[1]/RSS[5])),2)
  	 df<-c(length(coef(Ho))-length(coef(H1)),length(coef(Ho))-length(coef(H2)),
       	length(coef(Ho))-length(coef(H3)),length(coef(Ho))-length(coef(H4)))
  	 p<-round(1-pchisq(X,df),3)

      labs<-c("Ho","H1","H2","H3","H4")
      hyp<-c("Linf1=Linf2","K1=K2","t01=t02","Linf1=Linf2,K1=K2,t01=t02")
      labels<-c("Ho vs H1","Ho vs H2","Ho vs H3","Ho vs H4")
      compout<-data.frame(tests=labels,hypothesis=hyp,chisq=X,df=df,p=p)
      rss<-as.data.frame(cbind(labs,RSS));names(rss)<-c("model","rss")
      residuals_all<-as.data.frame(cbind(resid0,resid1,resid2,resid3,resid4))
      nlsout<-list(compout,summary(Ho),summary(H1),summary(H2),summary(H3), summary(H4),
             rss,residuals_all)
      names(nlsout)<-c("results",c(paste("model",labs)),"rss","residuals")
      return(nlsout)
}

