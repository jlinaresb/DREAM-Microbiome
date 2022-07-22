# Create datasets to run
# ===
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

get.data = function(outDir, phylotypes, deep, counts, level, early){
  # Load data
  meta = read.csv('../../extdata/metadata/metadata.csv', header = T)
  valencias = read.csv('../../extdata/community_state_types/cst_valencia.csv', row.names = 1)
  alpha = read.csv('../../extdata/alpha_diversity/alpha_diversity.csv', row.names = 1)
  
  if (phylotypes == T) {
    tax = read.csv(paste0('../../extdata/phylotypes/phylotype_', 
                          counts, '.', deep, '.csv'), 
                   header = T, row.names = 1)
    long.feats = readRDS(
      paste0('../../01_preprocess_data/data/feature_selection/phylotypes_',
             deep, '.rds'))$all
    de.feats = readRDS(
      paste0('../../01_preprocess_data/data/feature_selection/phylotypes_',
             deep, '_', early, '.rds'))
    outPath = paste0('phylotypes_', deep, '_', early, '.rds')
  } else{
    tax = read.csv(paste0('../../extdata/taxonomy/taxonomy_',
                          counts, '.', level, '.csv'), 
                   header = T, row.names = 1)
    long.feats = readRDS(
      paste0('../../01_preprocess_data/data/feature_selection/taxonomy_',
             counts, '_', level, '.rds'))$all
    de.feats = readRDS(
      paste0('../../01_preprocess_data/data/feature_selection/taxonomy_',
             level, '_', early, '.rds'))
    outPath = paste0('taxonomy_', counts, '_', level, '_', early, '.rds')
  }
  
  
  # Unique
  # ===
  features = unique(long.feats, de.feats)
  
  tax = tax[,match(features, colnames(tax))]
  
  res = data.frame(
    # valencias
    score = valencias$score,
    
    # alpha diversity
    phylo_entropy = alpha$phylo_entropy,
    
    # metadata
    collect_week = meta$collect_wk,
    delivery_week = meta$delivery_wk,
    NIH.Racial.Category = meta$NIH.Racial.Category,
    
    # metagenomic
    tax
  )
  
  res = fastDummies::dummy_cols(res, 
                                select_columns = 'NIH.Racial.Category',
                                remove_first_dummy = F,
                                remove_selected_columns = T)
  res = res[, -grep('NIH.Racial.Category_Unknown', colnames(res))]
  rownames(res) = meta$specimen
  
  # Delete project B and J
  res = res[-c(grep('B00', rownames(res)),
               grep('J00', rownames(res))),]
  
  outPath = paste0(outDir, outPath)
  rm(list = setdiff(ls(), c("res", "early", "outPath")))
  
  if (early == 28) {
    res$target = ifelse(res$delivery_week < 32, 'preterm', 'term')
    res = res[,-grep('delivery_week', colnames(res))]
  } else if(early == 32){
    res$target = ifelse(res$delivery_week < 37, 'preterm', 'term')
    res = res[,-grep('delivery_week', colnames(res))]
  }
  names(res) = make.names(names(res))
  saveRDS(res, file = outPath)
}


outDir = '../../02_training/toRun/'

# Arguments
phylotypes = c(T,F)
deep = c('1e_1', '1e0', '5e_1')      # 1e_1 1e0 5e_1
counts = 'relabd' # relabd nreads
level = c('species', 'genus', 'family') # species genus family
early = c(28, 32)        # 28 32


for (phylo in phylotypes) {
  if (phylo == T) {
    for (d in deep) {
      for (e in early) {
        get.data(outDir = outDir,
                 phylotypes = T,
                 deep = d,
                 counts = counts,
                 level = NULL,
                 early = e)
      }
    }
  } else if (phylo == F){
    for (l in level) {
      for (e in early) {
        get.data(outDir = outDir,
                 phylotypes = F,
                 deep = NULL,
                 counts = counts,
                 level = l,
                 early = e)
      }
    }
  }
}


# Merge datasets
files32 = list.files('../../02_training/toRun/', pattern = '32')

data32 = list()
# i = 1
for (i in seq_along(files32)) {
  
  data32[[i]] = readRDS(paste0('../../02_training/toRun/', files32[i]))
  data32[[i]] = subset(data32[[i]], select = -c(score, phylo_entropy, collect_week,
                                                NIH.Racial.Category_American.Indian.or.Alaska.Native,
                                                NIH.Racial.Category_Asian,
                                                NIH.Racial.Category_Black.or.African.American,
                                                NIH.Racial.Category_Native.Hawaiian.or.Other.Pacific.Islander,
                                                NIH.Racial.Category_White,
                                                target))
}

data32 = as.data.frame(data32)
cvrts32 = readRDS('../../02_training/toRun/phylotypes_1e_1_32.rds')
cvrts32 = subset(cvrts32, select = c(score, phylo_entropy, collect_week,
                                NIH.Racial.Category_American.Indian.or.Alaska.Native,
                                NIH.Racial.Category_Asian,
                                NIH.Racial.Category_Black.or.African.American,
                                NIH.Racial.Category_Native.Hawaiian.or.Other.Pacific.Islander,
                                NIH.Racial.Category_White,
                                target))
data32 = cbind.data.frame(cvrts32, data32)
saveRDS(data32, file = '../../02_training/toRun/all_32.rds')




files28 = list.files('../../02_training/toRun/', pattern = '28')

data28 = list()
# i = 1
for (i in seq_along(files28)) {
  
  data32[[i]] = readRDS(paste0('../../02_training/toRun/', files28[i]))
  data32[[i]] = subset(data28[[i]], select = -c(score, phylo_entropy, collect_week,
                                                NIH.Racial.Category_American.Indian.or.Alaska.Native,
                                                NIH.Racial.Category_Asian,
                                                NIH.Racial.Category_Black.or.African.American,
                                                NIH.Racial.Category_Native.Hawaiian.or.Other.Pacific.Islander,
                                                NIH.Racial.Category_White,
                                                target))
}

data28 = as.data.frame(data28)
cvrts28 = readRDS('../../02_training/toRun/phylotypes_1e_1_28.rds')
cvrts28 = subset(cvrts32, select = c(score, phylo_entropy, collect_week,
                                     NIH.Racial.Category_American.Indian.or.Alaska.Native,
                                     NIH.Racial.Category_Asian,
                                     NIH.Racial.Category_Black.or.African.American,
                                     NIH.Racial.Category_Native.Hawaiian.or.Other.Pacific.Islander,
                                     NIH.Racial.Category_White,
                                     target))
cvrts28 = cbind.data.frame(cvrts32, cvrts28)
saveRDS(cvrts28, file = '../../02_training/toRun/all_28.rds')



