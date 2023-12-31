## ----setup, message = FALSE------------------------------------------------------
# load packages =====
library(tidyverse)
library(readxl)
library(vcd)
library(EMT)
library(knitr)
library(ggpubr)
library(rstatix)


## ----load-corpus-size, message = FALSE-------------------------------------------
# load the corpus size table
# corpussize <- tibble::as_tibble(read.table(file = "/Volumes/GoogleDrive/Other computers/My MacBook Pro/Documents/Corpora/_corpusindo/Leipzig Corpora/corpus_total_size_per_file.txt", header = TRUE, sep = "\t", comment.char = "", quote = "")[-c(1, 13, 15), ])

# readr::write_tsv(corpussize, "data/corpussize.txt")
corpussize <- readr::read_tsv("data/corpussize.txt")


## ----load-concordance-BELI, message = FALSE, warning = FALSE---------------------
# mydat <- read_xlsx("data/BELI-main.xlsx")
mydat <- read_csv2("data/BELI-main.csv")
df_membelikan <- mydat %>% 
  filter(node == "membelikan")
df_membeli <- mydat %>% 
  filter(node == "membeli")
df_dibeli <- mydat %>% 
  filter(node == "dibeli")
df_dibelikan <- mydat %>% 
  filter(node == "dibelikan")
mydat_clause_type <- mydat |> 
  count(clause_type, sort = TRUE) |> 
  mutate(perc = n/sum(n) * 100,
         perc = round(perc, 1))
mydat_clause_type_binom <- binom.test(mydat_clause_type$n)
# 	Exact binomial test
# 
# data:  mydat_clause_type$n
# number of successes = 254, number of trials = 400, p-value = 7.382e-08
# alternative hypothesis: true probability of success is not equal to 0.5
# 95 percent confidence interval:
#  0.5857092 0.6822768
# sample estimates:
# probability of success 
#                  0.635



## ----membeli-cxntype-synvalence-count, message = FALSE---------------------------
cxn_type_membeli <- df_membeli %>% 
  mutate(schema = replace(schema, 
                          schema == "theme_obj_cxn", 
                          "[Goods]{.smallcaps}_Obj Construction"),
         schema = replace(schema, 
                          schema == "intransitive", 
                          "Intransitive Construction")) %>% 
  count(schema, syntactic_transitivity) %>% 
  arrange(desc(n))
cxn_type_membeli %>% 
  rename(`syntactic transitivity` = syntactic_transitivity,
         `token freq.` = n) %>% 
  kable(caption = "Construction types/schemas and syntactic valence/transitivity for *membeli*")


## ----membeli-cxntype-synvalence-binom, message = FALSE---------------------------
cxn_type_membeli <- cxn_type_membeli %>% 
         # create factor for plotting.
  mutate(syntactic_transitivity = factor(syntactic_transitivity, 
                                         levels = c("monotransitive", 
                                                    "intransitive")),
         N = sum(n),
         expected = N/nrow(.),
         alternatives = if_else(n < expected, "less", "greater"),
         
         # run binomial test
         binomtest = pmap(list(x = n, n = N), binom.test, conf.level = 0.99), 
         
         # extract confidence interval
         conf_low = map_dbl(binomtest, list("conf.int", 1)), 
         conf_high = map_dbl(binomtest, list("conf.int", 2)),
         
         # extract the estimate
         estimate = map_dbl(binomtest, "estimate"),
         
         # extract p-value
         pval = map_dbl(binomtest, "p.value"),
         signifs = "ns",
         signifs = if_else(pval < 0.05, "*", signifs),
         signifs = if_else(pval < 0.01, "**", signifs),
         signifs = if_else(pval < 0.001, "***", signifs)
         )
cxn_type_membeli %>% 
  select(-binomtest, -N, -alternatives, -expected) %>% 
  mutate(conf_low = round(conf_low, 2),
         conf_high = round(conf_high, 2),
         estimate = round(estimate, 2),
         pval = format(pval, digits = 4, scientific = TRUE)) %>% 
  kable()


## ----membeli-cxntype-visualisation, fig.cap="Proportion of the syntactic transitivity for *membeli*. The monotransitive pattern only realises the [Goods]{.smallcaps} as the direct object (see @tbl-membeli-proptest)", fig.asp=0.618, fig.width=7, dpi=300----
# get the base, "red" ggplot2 colour using `scales` package
ggred <- scales::hue_pal()(2)[1]

cxn_type_membeli %>% 
  # edit factor for plotting.
  mutate(schema = replace(schema, str_detect(schema, "Goods"), "GOODS_obj\n(Monotransitive)"),
         schema = replace(schema, str_detect(schema, "Intran"), "Deprofiled_obj\n(Intransitive)"),
         schema = factor(schema, levels = c("GOODS_obj\n(Monotransitive)", "Deprofiled_obj\n(Intransitive)"))) %>% 
  ggplot(aes(x = schema, 
             y = estimate, 
             fill = syntactic_transitivity)) + 
  geom_col(position = position_dodge(.9), colour = "gray50") +
  geom_text(aes(label = paste("n=", n, sep = "")), 
            position = position_dodge(.9),
            vjust = c(8.75, 1.25),
            hjust = c(0.5, -.5),
            colour = c("white", "black"),
            size = 9) +
  theme_bw() +
  scale_fill_manual(values = c(ggred, "gold")) +
  labs(y = "Proportion",
       fill = NULL,
       x = NULL) +
  theme(legend.position = "none",
        axis.title.y = element_text(size = 20),
        axis.text.y = element_text(size = 11.5),
        axis.text.x = element_text(size = 22)) +
  geom_errorbar(aes(ymin = conf_low, ymax = conf_high), 
                width = .2, position = position_dodge(.9))


## ----membeli-clause-type---------------------------------------------------------
intransitive_membeli_clause_type <- df_membeli |> 
  filter(schema == "intransitive") |> 
  count(clause_type, sort = TRUE) |> 
  mutate(percentage = n/sum(n) * 100)

intransitive_membeli_clause_type_binom <- binom.test(intransitive_membeli_clause_type$n)
intransitive_membeli_clause_type_binom_pval <- intransitive_membeli_clause_type_binom$p.value

intransitive_membeli_clause_type


## ----intransitive-membeli-subordinate-clause-count-------------------------------
df_membeli |> 
  filter(syntactic_transitivity=='intransitive', clause_type == "subordinate") |> 
  count(subordinate_clause_type)


## ----intransitive-membeli-in-main-clause-----------------------------------------
df_membeli |> 
  filter(syntactic_transitivity=='intransitive', clause_type == "main") |> 
  pull(node_sentences)


## ----intransitive-membeli-in-subordinate-clause----------------------------------
df_membeli |> 
  filter(syntactic_transitivity=='intransitive', clause_type == "subordinate") |> 
  pull(node_sentences)


## ----dibeli-cxntype-synvalence-count---------------------------------------------
cxn_type_dibeli <- df_dibeli %>% 
  filter(schema != "???") %>% 
  count(schema, syntactic_transitivity) %>%
  arrange(desc(n))


## ----dibeli-cxntype-synvalence-binom, eval = FALSE, echo = FALSE, include = FALSE----
## cxn_type_dibeli <- cxn_type_dibeli %>%
##   mutate(syntactic_transitivity = factor(syntactic_transitivity,
##                                          levels = c("intransitive",
##                                                     "transitive")),
##          N = sum(n),
##          # run binomial test
##          binomtest = pmap(list(x = n, n = N), binom.test, conf.level = 0.99),
## 
##          # extract confidence interval
##          conf_low = map_dbl(binomtest, list("conf.int", 1)),
##          conf_high = map_dbl(binomtest, list("conf.int", 2)),
## 
##          # extract the estimate
##          estimate = map_dbl(binomtest, "estimate"),
## 
##          # extract the p-value
##          pval = map_dbl(binomtest, "p.value"),
##          signifs = "ns",
##          signifs = if_else(pval < 0.05, "*", signifs),
##          signifs = if_else(pval < 0.01, "**", signifs),
##          signifs = if_else(pval < 0.001, "***", signifs),
##          schema = str_replace(schema, "theme", "goods"))


## ----dibeli-cxntype-count--------------------------------------------------------
cxn_type_dibeli2 <- df_dibeli %>% 
  filter(schema != "???") %>% 
  count(schema) %>%
  arrange(desc(n)) %>% 
  mutate(schema = str_replace(schema, "theme", "goods"),
         schema = replace(schema, schema == "subj_goods", "GOODS_pass.subj"),
         schema = replace(schema, schema == "subj_rate", "RATE_pass.subj"),
         schema = factor(schema, levels = c("GOODS_pass.subj", "RATE_pass.subj")),
         N = sum(n), 
         
         # run binomial test
         binomtest = pmap(list(x = n, n = N), binom.test, conf.level = 0.99), 
         
         # extract confidence interval
         conf_low = map_dbl(binomtest, list("conf.int", 1)), 
         conf_high = map_dbl(binomtest, list("conf.int", 2)),
         
         # extract the estimate
         estimate = map_dbl(binomtest, "estimate"),
         
         # extract the p-value
         pval = map_dbl(binomtest, "p.value"),
         signifs = "ns",
         signifs = if_else(pval < 0.05, "*", signifs),
         signifs = if_else(pval < 0.01, "**", signifs),
         signifs = if_else(pval < 0.001, "***", signifs))


## ----dibeli-cxntype-visualisation, fig.cap = "Constructional profiles of *dibeli*", fig.asp=0.618, fig.width=7, dpi=300----
cxn_type_dibeli2 %>% 
  ggplot(aes(x = schema, 
             y = estimate, 
             fill = schema)) + 
  geom_col(position = position_dodge(.9), colour = "gray50") +
  geom_text(aes(label = paste("n=", n, sep = "")), 
            position = position_dodge(.9),
            vjust = c(9, -.5),
            hjust = c(.5, -.75),
            size = 9,
            colour = c("white", "black")) +
  theme_bw() +
  # scale_fill_manual(values = c("limegreen", "gold")) +
  labs(y = "Proportion",
       fill = "Cxn Type",
       x = NULL) +
  theme(axis.text.x = element_text(size = 22),
        legend.position = "none",
        axis.title.y = element_text(size = 20),
        axis.text.y = element_text(size = 11.5)) +
  geom_errorbar(aes(ymin = conf_low, ymax = conf_high), 
                width = .2, position = position_dodge(.9))


## ----membelikan-cxntype-synvalence-count-----------------------------------------
cxn_type_membelikan <- df_membelikan %>% 
  count(schema, syntactic_transitivity) %>% 
  arrange(syntactic_transitivity, desc(n)) %>% 
  group_by(syntactic_transitivity) %>% 
  mutate(n_transitivity = sum(n)) %>%
  arrange(desc(n_transitivity), desc(n)) %>% 
  ungroup()

## retrieve the intransitive singleton for "membelikan"
df_membelikan %>% filter(syntactic_transitivity=='intransitive') %>% pull(node_sentences)


## ----membelikan-cxntype-synvalence-binom-----------------------------------------
padjs1 <- 0.05/3
padjs2 <- 0.01/3
padjs3 <- 0.001/3

synt_trans_membelikan <- cxn_type_membelikan %>% 
  # filter(schema != "intransitive") %>% 
  mutate(schema = str_replace(schema, "theme", "goods"), 
         schema = str_replace(schema, "recipient", "recipient/beneficiary"), 
         schema = replace(schema, schema == "intransitive", "deprofiled_obj"),
         schema = str_replace(schema, "_cxn$", ""), 
         syntactic_transitivity = factor(syntactic_transitivity, 
                                         levels = c("monotransitive", "ditransitive", "intransitive")), 
         schema = factor(schema, 
                         levels = c("goods_obj", "recipient/beneficiary_obj", "deprofiled_obj"))) %>% 
  group_by(syntactic_transitivity) %>% 
  summarise(n = sum(n))

synt_trans_membelikan <- synt_trans_membelikan %>% 
  mutate(N = sum(n), 
         
         # run binomial test
         binomtest = pmap(list(x = n, n = N), binom.test, conf.level = 0.99), 
         
         # extract confidence interval
         conf_low = map_dbl(binomtest, list("conf.int", 1)), 
         conf_high = map_dbl(binomtest, list("conf.int", 2)),
         
         # extract the estimate
         estimate = map_dbl(binomtest, "estimate"),
         
         # extract the p-value
         pval = map_dbl(binomtest, "p.value"),
         signifs = "ns",
         signifs = if_else(pval < padjs1, "*", signifs),
         signifs = if_else(pval < padjs2, "**", signifs),
         signifs = if_else(pval < padjs3, "***", signifs))


## ----membelikan-cxntype-synvalence-binom-pairwise--------------------------------
synt_trans_membelikan_vector <- synt_trans_membelikan$n
names(synt_trans_membelikan_vector) <- synt_trans_membelikan$syntactic_transitivity
synt_trans_membelikan_pairwise_binom <- pairwise_binom_test(synt_trans_membelikan_vector, 
                                                            p.adjust.method = "bonferroni",
                                                            conf.level = 0.99) %>% 
  mutate(p.adjt = paste(format(p.adj, digits = 4, scientific = TRUE), " (", p.adj.signif, ")", sep = ""))


## ----membelikan-cxntype-synvalence-multinomial-----------------------------------
length_valence <- length(synt_trans_membelikan$syntactic_transitivity)
prob_valence <- rep(1/length_valence, length_valence)
pmultinom <- EMT::multinomial.test(observed = synt_trans_membelikan$n, prob = prob_valence)
# p-value = 0


## ----membelikan-synvalence-visualisation, fig.asp=0.8, dpi=300, fig.width=7, fig.cap="Syntactic transitivity of *membelikan*", eval = FALSE, include = FALSE, echo = FALSE----
## synt_trans_membelikan %>%
##   ggplot(aes(x = syntactic_transitivity,
##              y = estimate,
##              fill = syntactic_transitivity)) +
##   geom_col(position = position_dodge(.9), colour = "gray50") +
##   geom_text(aes(label = paste("n=", n, sep = "")),
##             position = position_dodge(.9),
##             vjust = c(10, 4, -.5),
##             hjust = c(.5, .5, -.5),
##             size = c(8, 8, 7.5),
##             colour = c("white", "white", "black")) +
##   theme_bw() +
##   scale_fill_manual(values = c("limegreen", "royalblue1", "gold")) +
##   labs(y = "Proportion",
##        fill = NULL,
##        x = NULL) +
##   theme(legend.position = "none",
##         axis.title.y = element_text(size = 20),
##         axis.text.y = element_text(size = 11.5),
##         axis.text.x = element_text(size = 22)) +
##   geom_errorbar(aes(ymin = conf_low, ymax = conf_high),
##                 width = .2, position = position_dodge(.9)) # +
##   # ylim(NA, 1) +
##   # geom_segment(x = 1.3, xend = 2, y = 0.84, yend = 0.84) +
##   # geom_segment(x = 1.3, xend = 1.3, y = 0.84, yend = 0.82) +
##   # geom_segment(x = 2, xend = 2, y = 0.84, yend = 0.82) +
##   # annotate("text",
##   #          x = 1.7, y = 0.88,
##   #          label = pull(filter(synt_trans_membelikan_pairwise_binom, group1 == "monotransitive", group2 == "ditransitive"), p.adjt)) +
##   #
##   # geom_segment(x = 1, xend = 3, y = 0.96, yend = 0.96) +
##   # geom_segment(x = 1, xend = 1, y = 0.96, yend = 0.94) +
##   # geom_segment(x = 3, xend = 3, y = 0.96, yend = 0.94) +
##   # annotate("text",
##   #          x = 2, y = 1,
##   #          label = pull(filter(synt_trans_membelikan_pairwise_binom, group1 == "monotransitive", group2 == "intransitive"), p.adjt)) +
##   #
##   # geom_segment(x = 2, xend = 3, y = 0.38, yend = 0.38) +
##   # geom_segment(x = 2, xend = 2, y = 0.38, yend = 0.36) +
##   # geom_segment(x = 3, xend = 3, y = 0.38, yend = 0.36) +
##   # annotate("text",
##   #          x = 2.5, y = 0.42,
##   #          label = pull(filter(synt_trans_membelikan_pairwise_binom, group1 == "ditransitive", group2 == "intransitive"), p.adjt))


## ----membelikan-synvalence-visualisation-raw-freq, fig.asp=0.8, dpi=300, fig.width=7, fig.cap="Syntactic transitivity of *membelikan*"----
synt_trans_membelikan %>% 
  ggplot(aes(x = syntactic_transitivity, 
             y = n, 
             fill = syntactic_transitivity)) + 
  geom_col(position = position_dodge(.9), colour = "gray50") +
  geom_text(aes(label = paste("n=", n, sep = "")), 
            position = position_dodge(.9),
            vjust = c(10, 3, -.5),
            hjust = c(.5, .5, .5),
            size = c(8, 8, 7.5),
            colour = c("white", "white", "black")) +
  theme_bw() +
  scale_fill_manual(values = c("limegreen", "royalblue1", "gold")) +
  labs(y = "Raw frequency",
       fill = NULL,
       x = NULL) +
  theme(legend.position = "none",
        axis.title.y = element_text(size = 20),
        axis.text.y = element_text(size = 11.5),
        axis.text.x = element_text(size = 22)) # +
  #geom_errorbar(aes(ymin = conf_low, ymax = conf_high), 
  #              width = .2, position = position_dodge(.9)) # +
  # ylim(NA, 1) +
  # geom_segment(x = 1.3, xend = 2, y = 0.84, yend = 0.84) +
  # geom_segment(x = 1.3, xend = 1.3, y = 0.84, yend = 0.82) +
  # geom_segment(x = 2, xend = 2, y = 0.84, yend = 0.82) +
  # annotate("text",
  #          x = 1.7, y = 0.88,
  #          label = pull(filter(synt_trans_membelikan_pairwise_binom, group1 == "monotransitive", group2 == "ditransitive"), p.adjt)) +
  # 
  # geom_segment(x = 1, xend = 3, y = 0.96, yend = 0.96) +
  # geom_segment(x = 1, xend = 1, y = 0.96, yend = 0.94) +
  # geom_segment(x = 3, xend = 3, y = 0.96, yend = 0.94) +
  # annotate("text",
  #          x = 2, y = 1,
  #          label = pull(filter(synt_trans_membelikan_pairwise_binom, group1 == "monotransitive", group2 == "intransitive"), p.adjt)) +
  # 
  # geom_segment(x = 2, xend = 3, y = 0.38, yend = 0.38) +
  # geom_segment(x = 2, xend = 2, y = 0.38, yend = 0.36) +
  # geom_segment(x = 3, xend = 3, y = 0.38, yend = 0.36) +
  # annotate("text",
  #          x = 2.5, y = 0.42,
  #          label = pull(filter(synt_trans_membelikan_pairwise_binom, group1 == "ditransitive", group2 == "intransitive"), p.adjt))


## ----membelikan-cxntype-synvalence-visualisation, fig.asp=0.8, dpi=300, fig.width=7, fig.cap="Syntactic transitivity and construction types of *membelikan*", eval = FALSE, include = FALSE, echo = FALSE----
## 
## # get the base, "blue" ggplot2 colour using `scales` package
## ggblue <- scales::hue_pal()(3)[3]
## 
## ### 2.1 data preparation and binomial test for CI =====
## cxn_type_synt_trans_membelikan <- cxn_type_membelikan %>%
##   filter(schema != "intransitive") %>%
##   mutate(schema = str_replace(schema, "theme", "GOODS"),
##          schema = str_replace(schema, "recipient", "BEN/REC"),
##          schema = str_replace(schema, "_cxn$", ""),
##          syntactic_transitivity = factor(syntactic_transitivity,
##                                          levels = c("monotransitive", "ditransitive")),
##          schema = factor(schema, levels = c("GOODS_obj", "BEN/REC_obj")),
##          perc_schema = round(n/n_transitivity * 100, 2),
##          binomtest = pmap(list(x = n, n = n_transitivity),
##                           binom.test, conf.level = 0.99),
##          conf_low = map_dbl(binomtest, list("conf.int", 1)),
##          conf_high = map_dbl(binomtest, list("conf.int", 2)),
##          estimate = map_dbl(binomtest, "estimate"),
##          pval = map_dbl(binomtest, "p.value")
##          )
## 
## ### 2.2 visualisation proper =======
## cxn_type_synt_trans_membelikan %>%
##   ggplot(aes(x = syntactic_transitivity,
##            y = estimate,
##            fill = schema)) +
##   geom_col(position = position_dodge(.9), colour = "gray50") +
##   geom_text(aes(label = paste("n=", n, sep = "")),
##             position = position_dodge(.9),
##             vjust = c(9, -.35, 10, -.35),
##             hjust = c(.5, -.1, .5, -.1),
##             size = c(8, 7, 8, 7),
##             colour = c("white", "black", "white", "black")) +
##   theme_bw() +
##   scale_fill_manual(values = c(ggred, ggblue, ggblue, ggred, ggblue)) +
##   labs(y = "Proportion",
##        fill = NULL,
##        x = NULL) +
##   geom_errorbar(aes(ymin = conf_low, ymax = conf_high),
##                 width = .2, position = position_dodge(.9)) +
##   theme(axis.text.x = element_text(size = 22),
##         axis.title.y = element_text(size = 20),
##         axis.text.y = element_text(size = 11.5),
##         legend.text = element_text(size = 14),
##         legend.title = element_text(size = 18),
##         legend.position = "top")
## 


## ----membelikan-cxntype-synvalence-visualisation-raw, fig.asp=0.8, dpi=300, fig.width=7, fig.cap="Syntactic transitivity and construction types of *membelikan*"----

# get the base, "blue" ggplot2 colour using `scales` package
ggblue <- scales::hue_pal()(3)[3]

### 2.1 data preparation and binomial test for CI =====
cxn_type_synt_trans_membelikan <- cxn_type_membelikan %>% 
  filter(schema != "intransitive") %>% 
  mutate(schema = str_replace(schema, "theme", "GOODS"), 
         schema = str_replace(schema, "recipient", "BEN/REC"), 
         schema = str_replace(schema, "_cxn$", ""), 
         syntactic_transitivity = factor(syntactic_transitivity, 
                                         levels = c("monotransitive", "ditransitive")), 
         schema = factor(schema, levels = c("GOODS_obj", "BEN/REC_obj")),
         perc_schema = round(n/n_transitivity * 100, 2),
         binomtest = pmap(list(x = n, n = n_transitivity), 
                          binom.test, conf.level = 0.99), 
         conf_low = map_dbl(binomtest, list("conf.int", 1)), 
         conf_high = map_dbl(binomtest, list("conf.int", 2)), 
         estimate = map_dbl(binomtest, "estimate"), 
         pval = map_dbl(binomtest, "p.value")
         )

### 2.2 visualisation proper =======
cxn_type_synt_trans_membelikan %>% 
  ggplot(aes(x = syntactic_transitivity, 
           y = n, 
           fill = schema)) + 
  geom_col(position = position_dodge(.9), colour = "gray50") +
  geom_text(aes(label = paste("n=", n, sep = "")), 
            position = position_dodge(.9),
            vjust = c(9, -.35, 3, -.35),
            hjust = c(.5, .5, .5, .5),
            size = c(8, 7, 8, 7),
            colour = c("white", "black", "white", "black")) +
  theme_bw() +
  scale_fill_manual(values = c(ggred, ggblue, ggblue, ggred, ggblue)) +
  labs(y = "Raw frequency",
       fill = NULL,
       x = NULL) +
  # geom_errorbar(aes(ymin = conf_low, ymax = conf_high), 
  #              width = .2, position = position_dodge(.9)) +
  theme(axis.text.x = element_text(size = 22),
        axis.title.y = element_text(size = 20),
        axis.text.y = element_text(size = 11.5),
        legend.text = element_text(size = 14),
        legend.title = element_text(size = 18),
        legend.position = "top")



## ----membelikan-vs-membeli-for-GOODS-obj-----------------------------------------
goods_obj_membelikan <- cxn_type_synt_trans_membelikan %>% filter(schema == "GOODS_obj", syntactic_transitivity == "monotransitive") %>% pull(n)
goods_obj_membeli <- cxn_type_membeli %>% slice_max(n = 1, order_by = n) %>% pull(n)

chisq.test(c(goods_obj_membelikan, goods_obj_membeli))


## ----monotransitive-membelikan-clause-type---------------------------------------
membelikan_theme_object_clause_type <- count(filter(df_membelikan, syntactic_transitivity == "monotransitive", schema == "theme_obj_cxn"), schema, clause_type)


## ----coreferentiality-control----------------------------------------------------
coreferentiality_df <- df_membelikan %>% 
  filter(syntactic_transitivity == "monotransitive",
         str_detect(recipient_syntax, "MATRIX"))



## ----binom-oblique-ditransitive-membelikan---------------------------------------
# 1. data preparation ======
oblique_membelikan_df <- df_membelikan %>% 
  filter(syntactic_transitivity == "monotransitive") %>% 
  count(recipient_syntax) %>% 
  mutate(syntx = if_else(str_detect(recipient_syntax, "^PP"), 
                         "PP", 
                         "others")) %>% 
  group_by(syntx) %>% 
  summarise(n=sum(n)) %>% 
  mutate(perc = n/sum(n) * 100)
oblique_membelikan <- oblique_membelikan_df %>% 
  filter(syntx == "PP") %>% pull(n)
ditrans_membelikan <- df_membelikan %>% 
  filter(syntactic_transitivity == "ditransitive") %>% 
  nrow()
# 2. binomial test
binom.test(c(oblique_membelikan, ditrans_membelikan))


## ----pronominality-oblique-ditransitive-membelikan-1-----------------------------
benef_pron_mono <- df_membelikan %>% 
  filter(syntactic_transitivity %in% c("monotransitive"), 
         str_detect(recipient_syntax, "^PP")) %>% 
  count(recipient_pronominality) %>% 
  mutate(cxn = "monotransitive")

benef_pron_doubleobject <- df_membelikan %>% 
  filter(syntactic_transitivity %in% c("ditransitive")) %>% 
  count(recipient_pronominality) %>% 
  mutate(cxn = "ditransitive")

benef_pron <- bind_rows(benef_pron_mono, 
                        benef_pron_doubleobject) %>% 
  # merge personal-pronoun-suffix with personal-pronoun
  mutate(recipient_pronominality = str_replace(recipient_pronominality,
                                               "^personal\\-pronoun(\\-suffix)?$", 
                                               "pronoun")) %>% 
  group_by(cxn, recipient_pronominality) %>% 
  summarise(n = sum(n), .groups = "drop")

benef_pron_mtx <- benef_pron %>% 
  pivot_wider(names_from = "recipient_pronominality", values_from = "n") %>% 
  data.frame(row.names = 1) %>% 
  as.matrix()

benef_pron_mtx

fisher.test(benef_pron_mtx)


## ----pronominality-oblique-ditransitive-membelikan-2-----------------------------
benef_pron_merge <- benef_pron %>% 
  mutate(recipient_pronominality = replace(recipient_pronominality,
                                           recipient_pronominality %in% c("np", "proper-name"),
                                           "non_pronoun")) %>% 
  group_by(cxn, recipient_pronominality) %>% 
  summarise(n = sum(n), .groups = "drop")

benef_pron_merge_mtx <- benef_pron_merge %>% 
  pivot_wider(names_from = "recipient_pronominality", values_from = "n") %>% 
  data.frame(row.names = 1) %>% 
  as.matrix()

benef_pron_merge_mtx

chisq.test(benef_pron_merge_mtx) # assumption met for exp. frequency


## ----animacy-oblique-ditransitive-membelikan-------------------------------------
# 1. data preparation ======
benef_anim_monotransitive_oblique <- df_membelikan %>%
  filter(syntactic_transitivity %in% c("monotransitive"),
         str_detect(recipient_syntax, "^PP")) %>% 
  count(recipient_animacy) %>% 
  mutate(cxn = "monotransitive_oblique")
benef_anim_ditransitive <- df_membelikan %>%
  filter(syntactic_transitivity %in% c("ditransitive")) %>% 
  count(recipient_animacy) %>% 
  mutate(cxn = "ditransitive")
benef_anim_combined <- bind_rows(benef_anim_ditransitive, benef_anim_monotransitive_oblique)
benef_anim_combined_mtx <- benef_anim_combined %>% 
  pivot_wider(names_from = "recipient_animacy", values_from = "n", values_fill = 0L) %>% 
  data.frame(row.names = 1) %>% 
  as.matrix()
benef_anim_combined_mtx

# 2. Fisher-Yates Excat Test ======
fisher.test(benef_anim_combined_mtx)


## ----dibelikan-cxntype-count-----------------------------------------------------
df_dibelikan1 <- df_dibelikan %>% 
  filter(str_detect(schema, "^null_", negate = TRUE)) %>% 
  mutate(schema = str_replace(schema, "recipient", "BEN/REC"),
         schema = str_replace(schema, "theme", "GOODS"),
         schema = str_replace(schema, "money", toupper("money")),
         schema = str_replace_all(schema, "^([^_]+)_([^_]+)$", "\\2_pass.\\1"),
         schema = factor(schema, 
                         levels = c("GOODS_pass.subj",
                                    "MONEY_pass.subj",
                                    "BEN/REC_pass.subj")))

cxn_type_dibelikan <- df_dibelikan1 %>% 
  count(schema) %>% 
  mutate(prop = n/sum(n), prop = round(prop, 2),
         N = sum(n))


## ----dibelikan-cxntype-binom-----------------------------------------------------
padjs1 <- 0.05/3
padjs2 <- 0.01/3
padjs3 <- 0.001/3

cxn_type_dibelikan1 <- cxn_type_dibelikan %>% 
  
  # run binomial test
  mutate(binomtest = pmap(list(x = n, n = N), binom.test, conf.level = 0.99), 
         
         # extract confidence interval
         conf_low = map_dbl(binomtest, list("conf.int", 1)), 
         conf_high = map_dbl(binomtest, list("conf.int", 2)),
         
         # extract the estimate
         estimate = map_dbl(binomtest, "estimate"),
         pval = map_dbl(binomtest, "p.value"),
         
         # p-value
         signifs = "ns",
         signifs = if_else(pval < padjs1, "*", signifs),
         signifs = if_else(pval < padjs2, "**", signifs),
         signifs = if_else(pval < padjs3, "***", signifs))

## pairwise binom
cxn_type_dibelikan_vector <- cxn_type_dibelikan$n
names(cxn_type_dibelikan_vector) <- cxn_type_dibelikan$schema
cxn_type_dibelikan_binom_pairwise <- pairwise_binom_test(cxn_type_dibelikan_vector, conf.level = .99, p.adjust.method = "bonferroni") %>% 
  mutate(p.adjt = paste(format(p.adj, digits = 3, scientific = TRUE), " (", p.adj.signif, ")", sep = ""))



## ----dibelikan-cxntype-visualisasi, fig.cap="Constructional profiles of *dibelikan*", fig.asp = 0.618, fig.width=7, dpi = 300----
cxn_type_dibelikan1 %>% 
  ggplot(aes(x = fct_reorder(schema, -estimate), 
             y = estimate, 
             fill = schema)) + 
  geom_col(position = position_dodge(.9), colour = "gray50") +
  geom_text(aes(label = paste("n=", n, sep = "")), 
            position = position_dodge(.9),
            vjust = c(-.5, 5, 5),
            hjust = c(-.5, .5, .5),
            colour = c("black", "white", "white"),
            size = 7) +
  theme_bw() +
  # scale_fill_manual(values = c("limegreen", "gold")) +
  labs(y = "Proportion",
       fill = NULL,
       x = NULL) +
  theme(axis.text.x = element_text(size = 13),
        axis.text.y = element_text(size = 11.5),
        axis.title.y = element_text(size = 20),
        legend.position = "none") +
  geom_errorbar(aes(ymin = conf_low, ymax = conf_high), 
                width = .2, position = position_dodge(.9)) +
  ylim(NA, 0.95) +
  geom_segment(x = 1, xend = 2, y = 0.78, yend = 0.78) +
  geom_segment(x = 1, xend = 1, y = 0.78, yend = 0.74) +
  geom_segment(x = 2, xend = 2, y = 0.78, yend = 0.74) +
  annotate("text",
           x = 1.5, y = 0.82,
           label = cxn_type_dibelikan_binom_pairwise[3,][["p.adj.signif"]]) +

  geom_segment(x = 1, xend = 3, y = 0.9, yend = 0.9) +
  geom_segment(x = 1, xend = 1, y = 0.9, yend = 0.86) +
  geom_segment(x = 3, xend = 3, y = 0.9, yend = 0.86) +
  annotate("text",
           x = 2, y = 0.94,
           label = cxn_type_dibelikan_binom_pairwise[2,][["p.adj.signif"]]) +
  
  geom_segment(x = 2, xend = 3, y = 0.58, yend = 0.58) +
  geom_segment(x = 2, xend = 2, y = 0.58, yend = 0.54) +
  geom_segment(x = 3, xend = 3, y = 0.58, yend = 0.54) +
  annotate("text",
           x = 2.5, y = 0.62,
           label = cxn_type_dibelikan_binom_pairwise[1,][["p.adj.signif"]])

