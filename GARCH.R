#GARCH
#setwd("C:/win32/Sourcecode")#setwd("C:/work")
#���v���t�@�C���̓ǂݍ���
ret<-read.table("6Portdai_VAR1_L0w1T250ret",header=F,sep=",",nrows=-1)
#ret<-read.table("25Portdai_ret.csv",header=F,sep=",",nrows=-1)
#���Ҏ��v���܂��̓p�����[�^�̓ǂݍ���
hat<-read.table("6Portdai_VAR1_L0w1T250par.csv",header=F,sep=",",nrows=-1)
#hat<-read.table("25Portdai_VAR1_L0w1T250_par.csv",header=F,sep=",",nrows=-1)
#header=F�F1�s�ڂɗ񖼂�������Ă��Ȃ��Bnrows=�s�ڂ܂œǂݍ��ށA�}�C�i�X�̎����ׂāBskip=tau-1�ǂݔ�΂� R��1����(python��0����)

ndim =dim(ret)[2]#���Y��
nobs =250-1#�w�K���Ԑ�

#GARCH�̗\������p�����[�^�����l
a <- c(0.002,0.002,0.002,0.002,0.002,0.002)
A <- diag(c(0.2,0.2,0.2,0.2,0.2,0.2))
B <- diag(c(0.7,0.7,0.7,0.7,0.7,0.7))
ini.dcc <- c(0.2,0.2)
#�c�������߂�
for (tau in 1:2) { #250
  dvar = c()
  for (t in 1:nobs) {
    er <- as.numeric(ret[tau+nobs+1-t,])
          -colSums(matrix(as.numeric(hat[tau,])*c(1,as.numeric(ret[tau+nobs+2-t,])),ndim+1,ndim))
    dvar <- rbind(dvar,er)  
  }
  #as.numeric()�x�N�g�����Bmatrix(,�s��,��)�s�񉻁BcolSums()��̑��a
  In <- diag(ndim)
  #�t�@�[�X�g�X�e�[�WGARCH�p�����[�^����
  first.stage <- dcc.estimation1(dvar = dvar, a = a, A = A, 
                                 B = B, model = "diagonal", method = "BFGS")
  if (first.stage$convergence != 0) {
    cat("* The first stage optimization has failed.    *\n")
    cat("* See the list variable 'second' for details. *\n")
  }
    
  tmp.para <- c(first.stage$par, In[lower.tri(In)])
  estimates <- p.mat(tmp.para, model = "diagonal", ndim = ndim)
  esta <- estimates$a
  estA <- estimates$A
  estB <- estimates$B
  h <- vector.garch(dvar, esta, estA, estB)
  std.resid <- dvar/sqrt(h)
  #�\��
  h_t <-esta+diag(estA)*as.numeric(dvar[nobs,])*as.numeric(dvar[nobs,])+diag(estB)*as.numeric(h[nobs,])
  
  #�Z�J���h�X�e�[�WDCC�p�����[�^����
  second.stage <- dcc.estimation2(std.resid, ini.dcc, gradient = 1)
  if (second.stage$convergence != 0) {
    cat("* The second stage optimization has failed.   *\n")
    cat("* See the list variable 'second' for details. *\n")
  }
  
  dccpar <- second.stage$par
  q <- dcc.est(std.resid, second.stage$par)$Q
  q_t <- as.numeric(dccpar[1])*c(std.resid[nobs,])%*%t(c(std.resid[nobs,]))+(as.numeric(dccpar[2])+1)*matrix(c(q[nobs,]),ndim,ndim)-as.numeric(dccpar[1])*c(std.resid[(nobs-1),])%*%t(c(std.resid[(nobs-1),]))-as.numeric(dccpar[2])*matrix(c(q[(nobs-1),]),ndim,ndim)
  hij <- sqrt(diag(h_t))%*%diag((1/sqrt(diag(q_t))))%*%q_t%*%diag((1/sqrt(diag(q_t))))%*%sqrt(diag(h_t))
  H <- t(c(hij))
  write.table(H, "25Portdai_VAR1_L0w1T250_DCC.csv", quote=F, col.names=F, sep=',',append=T)
}