

####
#### Dimensional Consumer Data
####

# load the data
brand.ratings <- read.csv("http://goo.gl/IQl8nc")

# check it out
head(brand.ratings)
tail(brand.ratings)

summary(brand.ratings)
str(brand.ratings)

# Rescaling the data
# center and Z-score it

# example
x <- 1:1000
x.sc <- (x - mean(x)) / sd(x)
summary(x.sc)

# transform the brand data
brand.sc <- brand.ratings
brand.sc[, 1:9] <- data.frame(scale(brand.ratings[, 1:9]))
summary(brand.sc)


install.packages("devtools")
devtools::install_github("taiyun/corrplot", build_vignettes = TRUE)

library(corrplot)

corrplot(cor(brand.sc[, 1:9]), order="hclust")


# aggregate personality attributes by brand
brand.mean <- aggregate(. ~ brand, data=brand.sc, mean)
brand.mean

rownames(brand.mean) <- brand.mean[, 1] # use brand for the row names
brand.mean <- brand.mean[, -1]          # remove brand name column
brand.mean


#### basic visualization of the raw data

# heatmap of attribute by brand
library(gplots)
library(RColorBrewer)
heatmap(as.matrix(brand.mean), 
        col=brewer.pal(9, "YlOrRd"), Colv=NA, Rowv=NA,
        main="Brand attributes")


heatmap(as.matrix(brand.mean), 
        col=brewer.pal(9, "YlOrRd"), 
        main="Brand attributes")


####
#### Principal components
####

# Simple example
# create simple correlated data
set.seed(98286)
xvar <- sample(1:10, 100, replace=TRUE)
yvar <- xvar
yvar[sample(1:length(yvar), 50)] <- sample(1:10, 50, replace=TRUE)
zvar <- yvar
zvar[sample(1:length(zvar), 50)] <- sample(1:10, 50, replace=TRUE)
my.vars <- cbind(xvar, yvar, zvar)

# visualize
plot(yvar ~ xvar, data=jitter(my.vars))
cor(my.vars)

# principal components
my.pca <- prcomp(my.vars)
summary(my.pca)
my.pca

cor(my.pca$x)   # components have zero correlation

# biplot
biplot(my.pca, scale=TRUE)


## PCA for brand ratings
brand.pc <- prcomp(brand.sc[, 1:9])
summary(brand.pc)

plot(brand.pc, type="l")

biplot(brand.pc)    # very dense!


# try again with just the means
brand.mean
brand.mu.pc <- prcomp(brand.mean, scale=TRUE)
summary(brand.mu.pc)

biplot(brand.mu.pc, main="Brand positioning", cex=c(1.5, 1))



#### Exploratory Factor Analysis

library(nFactors)
nScree(brand.sc[, 1:9])
eigen(cor(brand.sc[, 1:9]))

factanal(brand.sc[, 1:9], factors=2)
factanal(brand.sc[, 1:9], factors=3)


kmo <- function(x)
  
{
  x <- subset(x, complete.cases(x))
  r <- cor(x)
  r2 <- r^2
  i <- solve(r)
  d <- diag(i)
  p2 <- (-i/sqrt(outer(d, d)))^2
  diag(r2) <- diag(p2) <- 0
  KMO <- sum(r2)/(sum(r2)+sum(p2))
  MSA <- colSums(r2)/(colSums(r2)+colSums(p2))
  return(list(KMO=KMO, MSA=MSA))
}

kmo(brand.sc[,1:9])

bartlett.sphere<-function(data){chi.square=-( (dim(data)[1]-1) -
                                                (2*dim(data)[2]-5)/6 )*
  log(det(cor(data,use='pairwise.complete.obs')));cat('chi.square value ',
                                                      chi.square , ' on ', (dim(data)[2]^2-dim(data)[2])/2, ' degrees of freedom.'
                                                      , ' p-value: ', 1-pchisq(chi.square,(dim(data)[2]^2-dim(data)[2])/2))}

bartlett.sphere(brand.sc[,1:9])


library(GPArotation)
(brand.fa.ob <- factanal(brand.sc[, 1:9], factors=3, rotation="oblimin"))

library(gplots)
library(RColorBrewer)
heatmap.2(brand.fa.ob$loadings, 
          col=brewer.pal(9, "YlOrRd"), trace="none", key=FALSE, dend="none",
          Colv=FALSE, cexCol = 1.2,
          main="\n\n\n\n\nFactor loadings for brand adjectives")


# plot the structure
library(semPlot)
semPaths(brand.fa.ob, what="est", residuals=FALSE,
         cut=0.3, posCol=c("white", "darkgreen"), negCol=c("white", "red"),
         edge.label.cex=0.75, nCharNodes=7)


# use regression scores
brand.fa.ob <- factanal(brand.sc[, 1:9], factors=3, rotation="oblimin", 
                        scores="Bartlett")
brand.scores <- data.frame(brand.fa.ob$scores)
brand.scores$brand <- brand.sc$brand
head(brand.scores)

brand.fa.mean <- aggregate(. ~ brand, data=brand.scores, mean)
rownames(brand.fa.mean) <- brand.fa.mean[, 1]
brand.fa.mean <- brand.fa.mean[, -1]
names(brand.fa.mean) <- c("Leader", "Value", "Latest")
brand.fa.mean


heatmap.2(as.matrix(brand.fa.mean), 
          col=brewer.pal(9, "YlOrRd"), trace="none", key=FALSE, dend="none",
          cexCol=1.2, main="\n\n\n\n\nMean factor score by brand")


# 

#### Multidimensional scaling
# distance matrix
brand.dist <- dist(brand.mean)

# metric MDS
(brand.mds <- cmdscale(brand.dist))
# plot it
plot(brand.mds, type="n")
text(brand.mds, rownames(brand.mds), cex=2)


# non-metric MDS alternative 
brand.rank <- data.frame(lapply(brand.mean, function(x) ordered(rank(x))))
str(brand.rank)

library(cluster)
library(MASS)
brand.dist.r <- daisy(brand.rank, metric="gower")

brand.mds.r <- isoMDS(brand.dist.r)

plot(brand.mds.r$points, type="n")
text(brand.mds.r$points, levels(brand.sc$brand), cex=2)
