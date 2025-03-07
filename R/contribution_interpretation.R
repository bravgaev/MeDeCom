########################################################################################################################################
## contribution_interpretation.R
## -------------------------------------------------------------------------------------------------------------------------------------
## This scripts contains functions for assocating LMC contributions with sample groupings and assessing statistical significance
## for the differences.
######################################################################################################################################## 

######################################################################################################################################## 
## GLOBALS

######################################################################################################################################## 
## FUNCTIONS

#' run.trait.association
#' 
#' Computes test statistics for all possible group assignments of samples defined in \code{medecom.set} and \code{rnb.set} and stores
#' heatmaps of p-values on the given location for all CG Subsets, Ks and lambdas present in \code{medecom.set}
#' 
#' @param medecom.set An object of type \code{\link{MeDeComSet}} as the result of \code{\link{runMeDeCom}} containing LMCs and their
#'                     proportions in the samples. The Set can contain multiple runs for different values of K and lambda.
#' @param pheno.data An object of type \code{\link[RnBeads]{RnBSet-class}} containing methylation data and metadata for the same samples for which 
#'                 \code{medecom.set} was computed or a data.frame of sample annotations (ann_S)
#' @param test.fun Test statistic used to compute p-values of differences between LMC contributions in pairwise sample comparisons.
#'                  Defaults to \code{t.test}.
#' @param plot.path Path to store the p-value heatmaps.
#' @param figure.format Character describing the format in which plots should be stored on disk. Either \code{"pdf"} or \code{"png"}.
#' 
#' @details This function creates a new folder names \code{pdfs} at the location given by \code{plot.path} and stores a heatmap for
#'           all possible Ks and lambdas defined in \code{medecom.set}. The p-values are produced by comparing the LMC contributions
#'           in all sample comparisons defined by \code{\link[RnBeads]{rnb.sample.groups}} on \code{rnb.set}. The employed test statistic for
#'           pariwise comparison can be specified by \code{test.fun}, for groups defining more than one group \code{\link{kruskal.test}}
#'           is employed. P-values lower than 0.01 are added to the heatmap.
#'           
#' @author Michael Scherer
#' 
#' @export
run.trait.association <- function(medecom.set,pheno.data,test.fun=t.test,plot.path=getwd(),figure.format="pdf"){
  cg_subsets <- medecom.set@parameters$cg_subsets
  Ks <- medecom.set@parameters$Ks
  lambdas <- medecom.set@parameters$lambdas
  if(!file.exists(plot.path)){
    stop(paste("Location",plot.path,"does not exist."))
  }
  if(!figure.format %in% c("pdf","png")){
    stop(paste("Invalid value for figure.format, needs to be 'pdf' of 'png'"))
  }
  base.path <- file.path(plot.path,figure.format)
  if(!file.exists(base.path)){
    dir.create(base.path)
  }
  for(s in cg_subsets){
    s.path <- file.path(base.path,paste0("Subset",s))
    if(!file.exists(s.path)){
      dir.create(s.path)
    }
    for(K in Ks){
      k.path <- file.path(s.path,paste0("K",K))
      if(!file.exists(k.path)){
        dir.create(k.path)
      }
      for(lambda in lambdas){
        p.vals <- link.to.traits(medecom.set=medecom.set,cg_subset=s,K=K,lambda=lambda,pheno.data=pheno.data,test.fun=test.fun)
        plot <- plot.p.val.heatmap(p.vals)
        fname <- paste0("trait_association_heatmap_lambda",lambda,figure.format)
        ggsave(filename=file.path(k.path,fname),plot=plot,device = figure.format)
        cors <- quantitative.trait.association(medecom.set=medecom.set,cg_subset=s,K=K,lambda=lambda,pheno.data=pheno.data)
        plot <- plot.correlation.heatmap(cors)
        fname <- paste0("quantitative_trait_association_lambda",lambda,figure.format)
        ggsave(filename=file.path(k.path,fname),plot=plot,device = figure.format)
      }
    }
  }
}

#' run.trait.association.single
#' 
#' Computes test statistics for all possible group assignments of samples defined in \code{medecom.set} and \code{rnb.set} and stores
#' heatmaps of p-values on the given location only for a given CG Subset, K and lambda.
#' 
#' @param medecom.set An object of type \code{\link{MeDeComSet}} as the result of \code{\link{runMeDeCom}} containing LMCs and their
#'                     proportions in the samples. The Set can contain multiple runs for different values of K and lambda.
#' @param pheno.data An object of type \code{\link[RnBeads]{RnBSet-class}} containing methylation data and metadata for the same samples for which 
#'                 \code{medecom.set} was computed or a data.frame of sample annotations (ann_S)
#' @param cg_subset The cg_subset of interest
#' @param K The selected value for number of LMCs (K)
#' @param lambda The selected value of the regularizer (lambda)
#' @param test.fun Test statistic used to compute p-values of differences between LMC contributions in pairwise sample comparisons.
#'                  Defaults to \code{t.test}.
#' 
#' @details Returns a list with two elements, each a heatmap as a ggplot object for the given \code{medecom.set}, \code{cg_subset} \code{K} and \code{lambda}. 
#'           The elements correpond to p-values of correlation ("quantivative") and t-tests ("qualitative") traits.
#'           The p-values are produced by comparing the LMC contributions in all sample comparisons defined by \code{\link[RnBeads]{rnb.sample.groups}} 
#'           on \code{rnb.set}. The employed test statistic for pariwise comparison can be specified by \code{test.fun}, for groups defining more than one group \code{\link{kruskal.test}}
#'           is employed. P-values lower than 0.01 are added to the heatmap.
#'           
#' @author Michael Scherer
#' 
#' @export
run.trait.association.single <- function(medecom.set,pheno.data,cg_subset=NULL,K=NULL,lambda=NULL,test.fun=t.test){
  if(is.null(cg_subset)){
    cg_subset <- medecom.set@parameters$cg_subsets[1]
  }else if (!(cg_subset %in%  medecom.set@parameters$cg_subsets)){
    stop("Specified value for cg_subset not in medecom.set")
  }
  if(is.null(K)){
    K <- medecom.set@parameters$Ks[1]
  }else if (!(K %in%  medecom.set@parameters$Ks)){
    stop("Specified value for K not in medecom.set")
  }
  if(is.null(lambda)){
    lambda <- medecom.set@parameters$lambdas[1]
  }else if (!(lambda %in%  medecom.set@parameters$lambdas)){
    stop("Specified value for lambda not in medecom.set")
  }
  ret.list <- list()
  p.vals <- linear.model(medecom.set=medecom.set,cg_subset=cg_subset,K=K,lambda=lambda,pheno.data=pheno.data)
  plot <- plot.p.val.heatmap.lm(p.vals)
  ret.list[["linear model"]] <- plot
  p.vals <- link.to.traits(medecom.set=medecom.set,cg_subset=cg_subset,K=K,lambda=lambda,pheno.data=pheno.data,test.fun=test.fun)
  plot <- plot.p.val.heatmap(p.vals)
  ret.list[["qualitative"]] <- plot
  cors <- quantitative.trait.association(medecom.set=medecom.set,cg_subset=cg_subset,K=K,lambda=lambda,pheno.data=pheno.data)
  plot <- plot.correlation.heatmap(cors)
  ret.list[["quantitative"]] <- plot
  return(ret.list)
}

#' linear.model
#' 
#' This function applies a linear model to determine if the LMC proportions are linked to one of the phenotypic traits. For numeric data
#' the standard least squares model is used, for categorical data we use logistic regression.
#'  
#' @param medecom.set An object of type \code{\link{MeDeComSet}} as the result of \code{\link{runMeDeCom}} containing LMCs and their
#'                     proportions in the samples. The Set can contain multiple runs for different values of K and lambda.
#' @param cg_subset The subset of sites used for computing LMCs in \code{medecom.set}.
#' @param K The K parameter, determining the number of LMCs to extract from \code{medecom.set}.
#' @param lambda The lambda parameter, determining the regularization used for the LMCs in \code{medecom.set}.
#' @param pheno.data An object of type \code{\link{RnBSet}} containing methylation data and metadata for the same samples for which 
#'                 \code{medecom.set} was computed or a data.frame of sample annotations (ann_S)
#'                 
#' @return A list with an element for each sample grouping defined by \code{\link{rnb.sample.groups}}. The first element of each element is
#' the Akaike Information Criterion (AIC) computed for the model.
#' 
#' @details Each element in the returned list is of length \code{K}, displaying the p-value of the statistical assocation of the
#'           contributions of the corresponding LMC to the output. The p-values are produced by comparing the LMC 
#'           contributions in all sample comparisons defined by \code{\link{rnb.sample.groups}} on \code{rnb.set}. 
#' @author Michael Scherer
#' 
#' @noRd

linear.model <- function(medecom.set,cg_subset,K,lambda,pheno.data){
  if(!inherits(pheno.data,"RnBSet") && !is.data.frame(pheno.data)){
    stop("Invalid value for pheno.data; needs to be RnBSet or data.frame")
  }
  if(inherits(pheno.data,"RnBSet")){
    if(!(length(samples(pheno.data))==medecom.set@dataset_info$n)){
      stop("Annotation does not match the number of samples in the MeDeComSet")
    }
  }
  if(is.data.frame(pheno.data)){
    if(!(nrow(pheno.data)==medecom.set@dataset_info$n)){
      stop("Annotation does not match the number of samples in the MeDeComSet")
    }
  }
  #require("RnBeads")
  props <- getProportions(medecom.set,cg_subset=cg_subset,K=K,lambda=lambda)
  res <- list()
  if(!(is.null(dim(props)))){
    names.grps <- colnames(pheno.data)
    for(i in 1:length(names.grps)){
      grp <- pheno.data[,i]
      if(is.numeric(grp)){
        lm.mod <- glm(grp~.,data=as.data.frame(t(props)))
        sum.lm <- summary(lm.mod)
        aic.model <- sum.lm$aic
        cofi <- lm.mod$coefficients
        p.vals <- rep(NA,length(cofi))
        p.vals[!is.na(cofi)] <- c(aic.model,sum.lm$coefficients[-1,"Pr(>|t|)"])
        names(p.vals) <- c("AIC",row.names(props))
      }else if(length(unique(grp))>2 && !(length(unique(grp))==ncol(props))){
        lm.mod <- glm(as.factor(grp)~.,data = as.data.frame(t(props)),family = binomial(link="logit"))
        sum.lm <- summary(lm.mod)
        aic.model <- sum.lm$aic
        cofi <- lm.mod$coefficients
        p.vals <- rep(NA,length(cofi))
        p.vals[!is.na(cofi)] <- c(aic.model,sum.lm$coefficients[-1,"Pr(>|z|)"])
        names(p.vals) <- c("AIC",row.names(props))
      }else{
        p.vals <- NA
      }
      res[[names.grps[i]]] <- p.vals
    }
  }
  return(res)
}

#' link.to.traits
#' 
#' This routine performs a statistical test to determine if the difference in LMC contributions is different for the sample groups
#' defined in \code{rnb.set}.
#' 
#' @param medecom.set An object of type \code{\link{MeDeComSet}} as the result of \code{\link{runMeDeCom}} containing LMCs and their
#'                     proportions in the samples. The Set can contain multiple runs for different values of K and lambda.
#' @param cg_subset The subset of sites used for computing LMCs in \code{medecom.set}.
#' @param K The K parameter, determining the number of LMCs to extract from \code{medecom.set}.
#' @param lambda The lambda parameter, determining the regularization used for the LMCs in \code{medecom.set}.
#' @param pheno.data An object of type \code{\link{RnBSet}} containing methylation data and metadata for the same samples for which 
#'                 \code{medecom.set} was computed or a data.frame of sample annotations (ann_S)
#' @param test.fun Test statistic used to compute p-values of differences between LMC contributions in pairwise sample comparisons.
#'                  Defaults to \code{t.test}.
#'                  
#' @return A list with an element for each sample grouping defined by \code{\link{rnb.sample.groups}}.
#' 
#' @details Each element in the returned list is of length \code{K}, displaying the p-value of the statistical assocation of the
#'           contributions of the corresponding LMC to the sample grouping. The p-values are produced by comparing the LMC 
#'           contributions in all sample comparisons defined by \code{\link{rnb.sample.groups}} on \code{rnb.set}. The employed test
#'           statistic for pariwise comparison can be specified by \code{test.fun}, for groups defining more than one group
#'           \code{\link{kruskal.test}} is employed.
#' @author Michael Scherer
#' 
#' @noRd

link.to.traits <- function(medecom.set,cg_subset,K,lambda,pheno.data,test.fun=t.test){
  if(!inherits(pheno.data,"RnBSet") && !is.data.frame(pheno.data)){
    stop("Invalid value for pheno.data; needs to be RnBSet or data.frame")
  }
  if(inherits(pheno.data,"RnBSet")){
    if(!(length(samples(pheno.data))==medecom.set@dataset_info$n)){
      stop("Annotation does not match the number of samples in the MeDeComSet")
    }
  }
  if(is.data.frame(pheno.data)){
    if(!(nrow(pheno.data)==medecom.set@dataset_info$n)){
      stop("Annotation does not match the number of samples in the MeDeComSet")
    }
  }
  #require("RnBeads")
  sample.grps <- rnb.sample.groups(pheno.data)
  props <- getProportions(medecom.set,cg_subset=cg_subset,K=K,lambda=lambda)
  res <- list()
  if(!(is.null(dim(props)))){
    names.grps <- names(sample.grps)
    for(i in 1:length(sample.grps)){
      grp <- sample.grps[[i]]
      names.traits <- names(grp)
      if(length(grp)==2){
        p.vals <- apply(props,1,function(x){
          test.fun(x[grp[[1]]],x[grp[[2]]])$p.val
        })
      }else if(length(grp)>2){
        if(inherits(pheno.data,"RnBSet")){
          vec <- rep(NA,length(samples(pheno.data)))
        }else{
          vec <- rep(NA,nrow(pheno.data))
        }
        for(name in names.traits){
          vec[grp[[name]]] <- name
        }
        vec <- as.factor(vec)
        p.vals <- apply(props,1,function(x){
          kruskal.test(x,vec)$p.val
        })
      }else{
        p.vals <- NA
      }
      res[[names.grps[i]]] <- p.vals
    }
  }
  return(res)
}

#' quantitative.trait.assocation
#' 
#' This routine performs a correlation test to determine if there is a correlation between any quantitative trait and LMC contributions.
#' 
#' @param medecom.set An object of type \code{\link{MeDeComSet}} as the result of \code{\link{runMeDeCom}} containing LMCs and their
#'                     proportions in the samples. The Set can contain multiple runs for different values of K and lambda.
#' @param cg_subset The subset of sites used for computing LMCs in \code{medecom.set}.
#' @param K The K parameter, determining the number of LMCs to extract from \code{medecom.set}.
#' @param lambda The lambda parameter, determining the regularization used for the LMCs in \code{medecom.set}.
#' @param pheno.data An object of type \code{\link{RnBSet}} containing methylation data and metadata for the same samples for which 
#'                 \code{medecom.set} was computed or a data.frame of sample annotations (ann_S)
#'                  
#' @return A list with an element for each quantitative trait present in \code{rnb.set}'s phenotypic information.
#' 
#' @details Each element in the returned list is of length \code{K}, displaying the result of a correlation test of the
#'           quantitative trait and the LMC proportions for each LMC. 
#' @author Michael Scherer
#' 
#' @noRd

quantitative.trait.association <- function(medecom.set,cg_subset,K,lambda,pheno.data){
  if(!inherits(pheno.data,"RnBSet") && !is.data.frame(pheno.data)){
    stop("Invalid value for pheno.data; needs to be RnBSet or data.frame")
  }
  #require("RnBeads")
  sample.grps <- names(rnb.sample.groups(pheno.data))
  if(inherits(pheno.data,"RnBSet")){
    ph <- pheno(pheno.data)
  }else{
    ph <- pheno.data
  }
  quant.traits <- colnames(ph)
  quant.traits <- quant.traits[!(quant.traits%in%sample.grps)]
  props <- getProportions(medecom.set,cg_subset=cg_subset,K=K,lambda=lambda)
  res <- list()
  if(!is.null(dim(props))){
    for(trait in quant.traits){
      trait.value <- ph[,trait]
      if(is.numeric(trait.value)){
        cors <- apply(props,1,function(x){
          cor.test(x,trait.value)
        })
      }else{
        cors <- NA
      }
      res[[trait]] <- cors
    }
  }
  return(res)
}


#' plot.p.val.heatmap
#' 
#' Produces a heatmap for the p-values produced in \code{\link{link.to.traits}}.
#' 
#' @param trait.res A list as the result of \code{\link{link.to.traits}}.
#' 
#' @return A plot object displaying the heatmap of the input p-values. P-values lower than 0.01 are added to the plot as numbers,
#'          otherwise the decadic logarithm of the p-value resembles the shading of the tiles.
#'          
#' @author Michael Scherer
#' @noRd

plot.p.val.heatmap <- function(trait.res){
  if(length(trait.res)!=0){
    require("ggplot2")
    require("reshape2")
    to.plot <- as.data.frame(trait.res)
    to.plot$LMC <- row.names(to.plot)
    to.plot <- melt(to.plot)
    colnames(to.plot)[2:3] <- c("Trait","PValue")
    to.plot$LogPValue <- log(to.plot$PValue)
    plot <- ggplot(to.plot,aes(x=LMC,y=Trait,fill=LogPValue))+geom_tile()+theme_bw()+scale_fill_gradient(low="red",high = "white")+
      geom_text(aes(label=ifelse(round(PValue,2)< 0.01,format(PValue,digits = 2),"")),size=5/(length(unique(to.plot$LMC))/5))+
      theme(axis.text.x = element_text(angle=90,hjust=1))
  }else{
    plot <- ggplot(data.frame(x=c(0,1),y=c(0.1)))+geom_text(x=0.5,y=0.5,label="No assocation found")+theme_bw()
  }
  return(plot)
}

#' plot.p.val.heatmap.lm
#' 
#' Produces a heatmap for the p-values of the linear model and the AIC produced in \code{\link{linear.model}}.
#' 
#' @param trait.res A list as the result of \code{\link{linear.model}}.
#' 
#' @return A plot object displaying the heatmap of the input p-values and the AIC. P-values lower than 0.01 are added to the plot as numbers,
#'          otherwise the decadic logarithm of the p-value resembles the shading of the tiles.
#'          
#' @author Michael Scherer
#' @noRd

plot.p.val.heatmap.lm <- function(trait.res){
  if(length(trait.res)!=0){
    require("ggplot2")
    require("reshape2")
    to.plot <- as.data.frame(trait.res)
    to.plot$LMC <- row.names(to.plot)
    to.plot$Type <- c("AIC",rep("LMC",nrow(to.plot)-1))
    to.plot <- melt(to.plot,id=c("Type","LMC"))
    colnames(to.plot) <- c("Type","LMC","Trait","AIC")
    plot.AIC <- ggplot(to.plot[to.plot$Type%in%"AIC",],aes(x="",y=Trait,fill=AIC))+geom_tile()+theme_bw()+scale_fill_gradient(low="blue",high = "white")+
                         geom_text(aes(label=round(AIC,2)),size=5/(length(unique(to.plot$Trait))/10))+
                         theme(axis.text.x = element_text(angle=90,hjust=1),axis.title = element_blank(),axis.ticks.x = element_blank())
    colnames(to.plot) <- c("Type","LMC","Trait","PValue")
    to.plot$LogPValue <- log(to.plot$PValue)
    plot.pval <- ggplot(to.plot[to.plot$Type%in%"LMC",],aes(x=LMC,y=Trait,fill=LogPValue))+geom_tile()+theme_bw()+scale_fill_gradient(low="red",high = "white")+
      geom_text(aes(label=ifelse(round(PValue,2)< 0.01,format(PValue,digits = 2),"")),size=5/(length(unique(to.plot$LMC))/3))+
      theme(axis.text.x = element_text(angle=90,hjust=1))
    plot <- grid.arrange(plot.AIC,plot.pval)
  }else{
    plot <- ggplot(data.frame(x=c(0,1),y=c(0.1)))+geom_text(x=0.5,y=0.5,label="No assocation found")+theme_bw()
  }
  return(plot)
}

#' plot.correlation.heatmap
#' 
#' Produces a correlation heatmap produced by \code{\link{quantitative.trait.assocation}}.
#' 
#' @param trait.res A list as the result of \code{\link{quantitative.trait.association}}.
#' 
#' @return A plot object displaying a heatmap of correlations and corresponding p-values. Correlations are color-coded and a color is added
#'          to the text according to the correlation test p-value (one for <0.01 and another for >0.01).
#'          
#' @author Michael Scherer
#' @noRd

plot.correlation.heatmap <- function(trait.res){
  if(length(trait.res)!=0 && !all(is.na(trait.res))){
    require("ggplot2")
    require("reshape2")
    to.plot <- c()
    for(trait in names(trait.res)){
      lmc.association <- trait.res[[trait]]
      temp.fr <- c()
      for(lmc in names(lmc.association)){
        cor.t <- lmc.association[[lmc]]
        p.val <- cor.t$p.value
        cori <- cor.t$estimate
        temp.fr <- rbind(temp.fr,c(lmc,p.val,cori))
      }
      temp.fr <- as.data.frame(temp.fr)
      temp.fr$Trait <- rep(trait,nrow(temp.fr))
      to.plot <- rbind(to.plot,temp.fr)
    }
    to.plot <- as.data.frame(to.plot)
    colnames(to.plot) <- c("LMC","PValue","Correlation","Trait")
    to.plot$PValue <- as.numeric(as.character(to.plot$PValue))
    to.plot$Correlation <- as.numeric(as.character(to.plot$Correlation))
    to.plot$Significant <- ifelse(round(to.plot$PValue,2)< 0.01,"<0.01",">0.01")
    plot <- ggplot(to.plot,aes(x=LMC,y=Trait,fill=Correlation,color=Significant))+geom_tile()+theme_bw()+
      scale_fill_gradient(low="white",high = "blue")+scale_color_manual(values=c("red","white"))+geom_text(aes(label=round(Correlation,2)),size=5/(length(unique(to.plot$LMC))/10))+
      theme(axis.text.x = element_text(angle=90,hjust=1))
  }else{
    plot <- ggplot(data.frame(x=c(0,1),y=c(0.1)))+geom_text(x=0.5,y=0.5,label="No assocation found")+theme_bw()
  }
  return(plot)
}
