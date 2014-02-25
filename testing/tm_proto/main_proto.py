# import tokenize to parse out sentences
# and POS tagging
from nltk import tokenize, pos_tag, word_tokenize, WordNetLemmatizer
from nltk.corpus import stopwords

# if tokenize doesn't work, use the folllowing command
# $ sudo python -m nltk.downloader -d /usr/share/nltk_data all

def createC1(transactions):
    c1 = []
    for sentence in transactions:
        for word in sentence:
            if not [word] in c1:
                c1.append([word])

    c1.sort()

    return map(frozenset, c1)

def scanD(transactions, candidates, min_support=0.01):
    sscnt = {}
    for tid in transactions:
        for can in candidates:
            if can.issubset(tid):
                sscnt.setdefault(can, 0)
                sscnt[can] += 1

    num_items = float(len(transactions))
    retlist = []
    support_data = {}
    for key in sscnt:
        support = sscnt[key] / num_items
        if support >= min_support:
            retlist.insert(0, key)
        support_data[key] = support
    return retlist, support_data

def aprioriGen(freq_sets, k):
    retList = []
    lenLk = len(freq_sets)
    for i in range(lenLk):
        for j in range(i + 1, lenLk):
            L1 = list(freq_sets[i])[:k - 2]
            L2 = list(freq_sets[j])[:k - 2]
            L1.sort()
            L2.sort()
            if L1 == L2:
                retList.append(freq_sets[i] | freq_sets[j])
    return retList

def apriori(dataset, minsupport=0.5):
    C1 = createC1(dataset)
    D = map(set, dataset)
    L1, support_data = scanD(D, C1, minsupport)
    L = [L1]
    k = 2
    while (len(L[k - 2]) > 0):
        Ck = aprioriGen(L[k - 2], k)
        Lk, supK = scanD(D, Ck, minsupport)
        support_data.update(supK)
        L.append(Lk)
        k += 1
             
    return L, support_data

if __name__ == "__main__":
    f = open("marriott.text")
    txt = f.readlines()
    all_txt = " ".join(txt).replace("\n", " ")
    f.close()

    stopset = stopwords.words('english')

    sentences = tokenize.sent_tokenize(all_txt)
    tagged_sentences = []

    for sentence in sentences:
        tagged_sentences.append(pos_tag(word_tokenize(sentence)))

    trans_file = []
    wnl = WordNetLemmatizer()

    for sentence in tagged_sentences:
        # remove stop words
        cleaned_words = [(word, tag) for (word, tag) in sentence if \
                word.lower() not in stopset]
        
        # destemming
        unstemmed_words = [(wnl.lemmatize(word), tag) for (word, tag) in \
                cleaned_words]

        #noun_words = [(word, tag) for (word, tag) in unstemmed_words if \
                #tag[0] == 'N']
        noun_words = [word for (word, tag) in unstemmed_words if \
                tag[0] == 'N']

        if len(noun_words) > 0:
            trans_file.append(noun_words)

    C1 = createC1(trans_file)
    D = map(set, trans_file)

    L1, support_data = scanD(D, C1)
