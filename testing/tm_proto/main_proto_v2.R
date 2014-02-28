st <- proc.time()

# libraries required for NLP. Note that one library may need to be installed from an alternate repo
# note that this package relies on rJava, which in turn relies on Java, and setting these two things up
# may be an inhuman pain...
library(openNLP)
library(NLP)
# install.packages("openNLPmodels.en", repos="http://datacube.wu.ac.at/", type="source")
library(openNLPmodels.en)

# use tm for destemming
# uses function stemDocument, which relies on package SnowballC
library(tm)

# use arules for association mining
library(arules)

# set up sample text from review
txt = readLines("~/marriott/App_Performance/testing/tm_proto/marriott.text")
txt_string <- as.String(txt)

# create annotator objects
sent_token_annotator <- Maxent_Sent_Token_Annotator()
word_token_annotator <- Maxent_Word_Token_Annotator()
pos_tag_annotator <- Maxent_POS_Tag_Annotator()

txt_sents <- annotate(txt_string, sent_token_annotator)

# sentences can now be referenced using txt_string[txt_sents][sentence_number]

sentences <- vector(mode="list", length=length(txt_sents))
sent_num <- 1

for (sentence in txt_string[txt_sents])
{
  txt_pos <- annotate(sentence, list(sent_token_annotator, 
                                          word_token_annotator,
                                          pos_tag_annotator))

  # combine this part into one subset
  txt_pos_words <- subset(txt_pos, type=="word")
  cnt <- sum(substr(unlist(txt_pos_words$features), 1, 1) == "N")
  if (cnt == 0) next
  # this could be improved
  txt_pos_nouns <- subset(txt_pos_words, substr(unlist(features), 1, 1) == "N")

  #txt_pos_nouns <- subset(txt_pos_words, substr(features, 13, 13) == "N") 
  
  #destem nouns
  if (length(txt_pos_words) > 0)
  {
    destemmed <- stemDocument(as.character(as.String(sentence)[txt_pos_nouns]))
    sentences[[sent_num]] <- sort(unique(tolower(destemmed)))
    
    sent_num <- sent_num + 1
  }
}

# since some sentences don't have nouns, the sentences list will have some
# null elements. remove them
sentences[sapply(sentences, is.null)] <- NULL

# convert sentences to transactions type for association mining
trans <- as(sentences, "transactions")
rules <- apriori(trans, parameter=list(supp=0.01, target="rules"))
words <- c()
for (each in sentences)
{
  words <- c(each, words)
}

DF <- as.data.frame(table(words))
DF_sum <- DF[order(DF[,2], decreasing=T), ]

print(proc.time() - st)