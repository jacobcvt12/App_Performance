# import tokenize to parse out sentences
# and POS tagging
from nltk import tokenize, pos_tag, word_tokenize
from nltk.corpus import stopwords

# if tokenize doesn't work, use the folllowing command
# $ sudo python -m nltk.downloader -d /usr/share/nltk_data all

f = open("marriott.text")
txt = f.readlines()
all_txt = " ".join(txt).replace("\n", " ")
f.close()

stopset = stopwords.words('english')

sentences = tokenize.sent_tokenize(all_txt)
tagged_sentences = []

for sentence in sentences:
    words = word_tokenize(sentence)
    tagged_words = pos_tag(words)


    tagged_sentences.append(pos_tag(word_tokenize(sentence)))
