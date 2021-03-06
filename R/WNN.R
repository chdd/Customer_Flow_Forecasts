# 计算两个序列的相似度
similarity <- function(data_v, method){
  # 计算相似度
  if(method=="euclidean"){ # 欧式距离
    row <- nrow(data_v)
    res <- vector()
    for(i in 1:(row-1)){
      q <- sqrt(sum((data_v[i,]-data_v[row,])*(data_v[i,]-data_v[row,])))
      if(is.nan(q)){
        q <- 0
      }
      res <- c(res,q)
    }
    # 使其在（0,1）范围内
    dmax <- max(res)
    res <- 1-(res/dmax) #使其返回的值越大表示越接近
    return(res)
  }else if(method=="cosine"){ # 形状 余弦相似度
    row <- nrow(data_v)
    res <- vector()
    for(i in 1:(row-1)){
      q <- (sum(data_v[i,]*data_v[row,]))/(sqrt(sum(data_v[i,]*data_v[i,])*sum(data_v[row,]*data_v[row,])))
      if(is.nan(q)){
        q <- 0
      }
      res <- c(res,q)
    }
    return(res)
  }else if(method=="correlation"){ #相关系数
    row <- nrow(data_v)
    res <- vector()
    for(i in 1:(row-1)){
      mean1 <- mean(data_v[i,])
      mean2 <- mean(data_v[row,])
      a <- sum((data_v[i,]-mean1)*(data_v[row,]-mean2))
      b <- sqrt(sum((data_v[i,]-mean1)*(data_v[i,]-mean1)*(data_v[row,]-mean2)*(data_v[row,]-mean2)))
      q <- a/b
      if(is.nan(q)){
        q <- 0
      }
      res <- c(res,q)
    }
    return(res)
  }else if(method=="MAPE"){ #平均绝对百分误差（MAPE）
    row <- nrow(data_v)
    res <- vector()
    for(i in 1:(row-1)){
      cahce <- data_v[row,]-data_v[i,]
      sum_M <- 0
      N <- length(cahce)
      for(j in 1:N){
        sum_M <- sum_M+abs(cahce[j])
      }
      q <- sum_M/N
      res <- c(res,q)
    }
    return(res)
  }else if(method=="SDE"){ #误差标准偏差（SDE）
    row <- nrow(data_v)
    res <- vector()
    for(i in 1:(row-1)){
      Eh <- data_v[i,]-data_v[row,]
      q <- sqrt( mean((Eh - mean(Eh))*(Eh - mean(Eh))))
      res <- c(res,q)
    }
    return(res)
  }
}
# WNN预测
WNN <- function(data_v,N){

  # 将数据转换成 row=N的矩阵
  dim(data_v) <- c(N,length(data_v)/N)
  data_v <- t(data_v) #转置

  # 计算相似度
  sim <- similarity(data_v,method = 'euclidean')

  distance <- data.frame(index=1:length(sim), dist=sim)

  #相似度降序排序
  distance <- distance[order(-distance[,"dist"]),] #相似度降序

  # 截取前K个相似度进行计算
  K=1;
  for(i in 2:length(distance)){
    if(distance$dist[i]>=(distance$dist[1]/2)){
      K <- K+1
    }
  }
  N <- distance$dist[K]-distance$dist[1]
  alpha_sum <- 0
  L_a <- 0
  for(i in 1:K){
    alpha <- (distance$dist[K]-distance$dist[i])/N
    alpha_sum <- alpha_sum+alpha
    L_a <- L_a+alpha*data_v[distance$index[i]+1,]
  }
  L_d <- L_a/alpha_sum
  return(L_d)
}

#WNN模型说明:找出预测序列前N天相似序列的后面来预测


#sample
options(stringsAsFactors=F,scipen=99)
rm(list=ls());gc()
library(sqldf)
require(data.table)
library(recharts)
da<- fread("/Users/yuyin/Downloads/笔记学习/天池比赛/IJCAI-17口碑商家客流量预测/data/dataset/feature/train_all.txt",header = FALSE)

#取14得倍数的长度序列  预测20161018-20161031
re=sqldf("select V1,V2,V6 from da where V2>=20160712 and V2<=20161017 order by V1,V2")
shop_id=unique(re$V1)
out={}
for (i in 1:length(shop_id)){
tmp=re[which(re$V1==shop_id[i]),]
d=tmp$V6
if(sum(d)!=0){
fore_WNN <- WNN(d,14)
  }else{
fore_WNN <- rep(0,14)
  }
a=c(as.character(shop_id[i]),fore_WNN)
out=rbind(out,a)
}
out[is.nan(out)] <- 0
write.table (out, file ="/Users/yuyin/Downloads/笔记学习/天池比赛/IJCAI-17口碑商家客流量预测/data/dataset/feature/wnn_18_31.txt",sep =",",row.names = F,col.names=F,quote =F)

