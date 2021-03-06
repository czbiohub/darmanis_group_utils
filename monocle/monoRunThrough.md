monoRunThrough
================
Lincoln Harris
2.13.18

**This is an example workbook for running Monocle for trajectory inference from single-cell RNA-seq data**

*A more detailed description of all of the steps demonstrated here can be found at:* <http://cole-trapnell-lab.github.io/monocle-release/docs/>

### Loading Data

Load library

``` r
library(monocle)
```

Load data frames

``` r
raw_data <- read.csv('all_NE_raw.csv', header=TRUE)
row.names(raw_data) <- raw_data[,1]
raw_data <- raw_data[ ,-1]

meta_data <- read.csv('all_NE_meta.csv', header=TRUE)
row.names(meta_data) <- meta_data[,1]
meta_data <- meta_data[ ,-1]
```

Sanity check

``` r
dim(raw_data)
dim(meta_data)
```

Create annotated data frame from meta\_data

``` r
meta_data_anno <- new("AnnotatedDataFrame", data = meta_data)
```

Create CellDataSet object

``` r
cds_NE <- newCellDataSet(cellData = as.matrix(raw_data), phenoData = meta_data_anno, featureData = NULL, expressionFamily = negbinomial.size())
```

Estimate size and dispersion

``` r
cds_NE <- estimateSizeFactors(cds_NE)
cds_NE <- estimateDispersions(cds_NE)
```

### Constructing single-cell trajectories

Choosing genes that define progress, using *dpFeature* technique

``` r
cds_NE <- detectGenes(cds_NE, min_expr = 0.1)
fData(cds_NE)$use_for_ordering <- fData(cds_NE)$num_cells_expressed > 0.05 * ncol(cds_NE)
```

Find genes expressed in &gt;10 cells

``` r
all_NE_expressed_genes <- row.names(subset(fData(cds_NE), num_cells_expressed >= 10))
```

Plot PC variance

``` r
plot_pc_variance_explained(cds_NE, return_all = F, verbose = T, max_components = 100) 
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-9-1.png)

Run dimensionality reduction

``` r
cds_NE <- reduceDimension(cds_NE, max_components = 2, norm_method = 'log', num_dim = 20, reduction_method = 'tSNE', verbose = T)
```

Cluster cells & plot

``` r
cds_NE <- clusterCells(cds_NE, verbose = F)
```

    ## Distance cutoff calculated to 1.7319

``` r
plot_cell_clusters(cds_NE)
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-11-1.png)

Refine clustering params

``` r
plot_rho_delta(cds_NE, rho_threshold = 2, delta_threshold = 4 )
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-12-1.png)

...and recluster

``` r
cds_NE <- clusterCells(cds_NE, rho_threshold = 3, delta_threshold = 10, skip_rho_sigma = T, verbose = F)
plot_cell_clusters(cds_NE)
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-13-1.png)

Differential gene expression test

``` r
clustering_DEG_genes_NE <- differentialGeneTest(cds_NE[all_NE_expressed_genes,], fullModelFormulaStr = '~Cluster')
```

Select top 1000 genes

``` r
all_NE_ordering_genes <- 
  row.names(clustering_DEG_genes_NE)[order(clustering_DEG_genes_NE$qval)][1:1000]

cds_NE <- setOrderingFilter(cds_NE, ordering_genes = all_NE_ordering_genes)
cds_NE <- reduceDimension(cds_NE, method = 'DDRTree')
cds_NE <- orderCells(cds_NE)
```

...And plot

``` r
plot_cell_trajectory(cds_NE, color_by = "State")
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-16-1.png)

``` r
plot_cell_trajectory(cds_NE, color_by = "origin")
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-16-2.png)

``` r
plot_cell_trajectory(cds_NE, color_by = "age")
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-16-3.png)

``` r
plot_cell_trajectory(cds_NE, color_by = "Cluster")
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-16-4.png)

A different way of plotting trajectories

``` r
# most basic case
plot_complex_cell_trajectory(cds_NE, color_by = 'Cluster')
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-17-1.png)

``` r
plot_complex_cell_trajectory(cds_NE, color_by = 'State')
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-17-2.png)

``` r
plot_complex_cell_trajectory(cds_NE, color_by = 'age')
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-17-3.png)

``` r
# a bit more complicated
plot_complex_cell_trajectory(cds_NE, color_by = 'age', cell_size = 0.5, cell_link_size = 0.3) + scale_size(range = c(0.2, 0.2))
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-17-4.png)

### BEAM Analysis

*BEAM (Branched Expression Analysis Modeling)* finds genes that drive the branching event at the specified branch point.

``` r
all_BEAM1 <- BEAM(cds_NE, branch_point = 1)
all_BEAM1 <- all_BEAM1[order(all_BEAM1$qval),]
```

....and plot

``` r
plot_genes_branched_heatmap(cds_NE[row.names(subset(all_BEAM1, qval < 1e-20)),], branch_point = 1, cluster_rows = T, show_rownames = T)
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-19-1.png)

Sorting BEAM genes so that we're only grabbing the ones with the highest qval that are expressed in &gt;100 cells. Call this 'sub\_BEAM'

``` r
dim(all_BEAM1)

all_BEAM1_order <- all_BEAM1[order(all_BEAM1$qval),]
dim(all_BEAM1_order)

sub_BEAM1 <- all_BEAM1_order[1:100,]
sub_BEAM1 <- sub_BEAM1[row.names(subset(sub_BEAM1, num_cells_expressed > 100)),]
dim(sub_BEAM1)

#write.csv(sub_BEAM1, file = "sub_BEAM1.csv")
```

### Clustering Genes by Pseudotemporal Expression Pattern

First find diff. expressed genes

``` r
diff_NE <- differentialGeneTest(cds_NE[all_NE_expressed_genes,], fullModelFormulaStr = "~sm.ns(Pseudotime)")

sig_gene_names <- row.names(subset(diff_NE, qval < 1e-45))
```

Now plot

``` r
plot_pseudotime_heatmap(cds_NE[sig_gene_names,], show_rownames = T)
```

![](monoRunThrough_files/figure-markdown_github/unnamed-chunk-22-1.png)
