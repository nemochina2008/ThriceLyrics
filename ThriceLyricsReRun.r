# Packages:
library(tidyverse)
library(tidytext)
library(lubridate)
library(stringr)
library(broom)
library(RColorBrewer)

library(gplots)
library(ggrepel)
library(scales)
library(hrbrthemes)
library(wordcloud)
library(gridExtra)

library(knitr)

# load dataset ------------------------------------------------------------

df <- read.csv('thrice.df.csv', header=TRUE, stringsAsFactors = FALSE)

glimpse(df)
# song ID, year, track num = integer
# all else chr

# use lubridate pkg to tranform length and lengthS
# turn album var into a factor variable for each unique album!
?ms()  # transforms chr/num vector into period object
?seconds()  # create period object in seconds

df <- df %>% 
       mutate(album = factor(album, levels = unique(album)),
              length = ms(length),
              lengthS = seconds(length))

glimpse(df)
# both length and lengthS are now Period/S4 variables!
# album is a factor!


# Lyrics analysis ---------------------------------------------------------

df <- df %>%
  mutate(lyrics = str_replace_all(lyrics, '\'', ' ')) %>%   # replace apostrophes in lyrics with blank
  mutate(numLines = str_count(lyrics, '<br>') + 1) %>%      # num of lines per song
  mutate(numWord = str_count(lyrics, ' ') + 1)              # num of words per song

lineToken <- df %>%
  unnest_tokens(line, lyrics, token = stringr::str_split, pattern = ' <br>') %>% 
  mutate(lineCount = row_number())
lineToken

wordToken <-  lineToken %>% 
  unnest_tokens(word, line) %>% 
  mutate(wordCount = row_number()) %>% 
  select(-numLines, -numWord)
wordToken # uncleaned unigrams containing all 'stop words' such as 'I', 'you', 'we', 'very', etc. etc.


countWord <- count(wordToken, word, sort=TRUE)
countWord <- head(countWord, 100)
empty <- data.frame(a=character(100),b=rep('|',100),c=character(100),
                    stringsAsFactors = FALSE)
# 'the' is most common....


data("stop_words")     # data base of 'stop words' to clean unigrams.
stop_words %>% print(n = 1149)

wordToken2 <- wordToken %>% 
  anti_join(stop_words) %>%
  arrange(wordCount)

countWord2 <- count(wordToken2, word, sort=TRUE)
countWord2 <- head(countWord2, 100)
# with no stop words, 'eyes', ''ll', ''ve', and 'love', 'light' are most common
# interesting in -light- of the fact that sentiment-score wise Thrice songs are overtly negative...



#################################################################################
aggregate(wordToken2$numWord, by = list(wordToken2$album), FUN = sum) %>% 
  arrange(-x)
### right syntax but numword is WRONG, each numword has own row with # words for entire album!
# all rows spread by singular WORD, need to spread each row by SONG, calculate numWord for each, aggregate for each album???


###    CHECKING DATASET WITH SIMPLE DPLYR VERBS!   ####



df %>% aggregate(.$numWord, by = list(albumList), FUN = count)   # by - must be list...   sum NOT meaningful for factors...
albumList <- as.vector(df$album)
count(df$numWord)


df %>% summarise(Num.Songs = n()) # 103 songs in total

df %>% group_by(album) %>% 
  summarise(count = n()) %>% 
  arrange(desc(count)) # songs per album (by order of # of songs desc)

df %>% group_by(title) %>%
  select(title, numLines, album) %>% 
  arrange(desc(numLines))    # songs with most # of lines

# words per song?
df %>% group_by(title) %>% 
  select(title, numWord, album) %>% 
  arrange(desc(numWord))    # The Weight has the most words (all incl. stop words)... also includes <br> though...

aggregate(df$numWord, by = list(df$album), FUN = sum) %>% 
  arrange(desc(x))   # instrumentals still count the blank as 1, but insignificant.
# numWord by album

df %>% filter(album == "Vheissu") %>% select(numWord) %>% sum()

aggregate(df$numWord, by = list(df$album), FUN = sum, na.rm = F)

wordToken$word[wordToken$word == "light"]

###
###
###
###
###

df %>% aggregate(lyrics, by = list(title), FUN = sum)

df %>% tokenize(lyrics)
tokenize(df$lyrics)
aggregate(df$lyrics, by = list(df$title), FUN = sum)

TEST <- df %>%
  mutate(lyrics = str_replace_all(lyrics, '\'', ' ')) %>%
  unnest_tokens(line, lyrics, token = stringr::str_split, pattern = ' <br>') %>% 
  unnest_tokens(word, line) %>%
  anti_join(stop_words) %>%
  select(-length, -lengthS) %>% 
  group_by(title)

WordsPerSong <- df %>%
  mutate(lyrics = str_replace_all(lyrics, '\'', ' ')) %>%
  unnest_tokens(line, lyrics, token = stringr::str_split, pattern = ' <br>') %>% 
  unnest_tokens(word, line) %>%           # include stop words (they are still words in the lyrics for the total count)
  group_by(title) %>% 
  summarize(wordcounts = n()) %>%    # # of rows per group(title)  ????
  arrange(desc(wordcounts))

WordsPerSong1111 <- df %>%
  mutate(lyrics = str_replace_all(lyrics, '\'', ' ')) %>%
  unnest_tokens(line, lyrics, token = stringr::str_split, pattern = ' <br>') %>% 
  unnest_tokens(word, line) %>%           # include stop words (they are still words in the lyrics for the total count)
  group_by(title)

LinesPerSong <- df %>%
  mutate(lyrics = str_replace_all(lyrics, '\'', ' ')) %>%
  unnest_tokens(line, lyrics, token = stringr::str_split, pattern = ' <br>') %>% 
  group_by(title) %>% 
  summarise(linecounts = n()) %>% 
  arrange(desc(linecounts))

PerSong <- full_join(WordsPerSong, LinesPerSong, by = "title")

sum(str_count(df$lyrics, "<br>"))
sum(str_count(df$lyrics, "light"))
  
# i actuall yfucking solved it and i dont know how.
asdf <- TEST %>% group_by(title) %>% 
  summarize(wordcounts = n()) %>%    # # of rows per group(title)  ????
  arrange(desc(wordcounts))

# Histogram of Word counts (per Song)
WordsPerSong %>% ggplot(aes(x = wordcounts)) + geom_histogram(binwidth = 10) +
  geom_vline(xintercept = mean(WordsPerSong$wordcounts), color = "red") +
  scale_x_continuous(breaks = pretty_breaks(n = 10)) +
  scale_y_continuous(breaks = pretty_breaks(n = 10))

df %>% filter(title == "As The Crow Flies")


wordToken2 %>% bind_tf_idf(word, album , n)

TEST %>% group_by(title) %>% 
  count(word)

TEST %>% group_by(title) %>% 
  summarize(lyri = n(word))

TEST %>% group_by(title) %>% 
  summarize(lets = sum(word))

df %>% length(lyrics)
length()

TEST %>% (title) %>% 
  count(title, word)

aggregate(TEST$word, by = list(TEST$title), "count")
aggregate(TEST[, "word"], by = list(TEST$title), "count")



paste(TEST$lyrics)

lTest %>% n_distinct(line)


# Sentiment analysis:

tidy_lyrics <- wordToken2 %>% 
  filter(!grepl('[0-9]', word)) %>% 
  left_join(get_sentiments("bing"), by = "word") %>% 
  group_by(album) %>%    # will show up in ALL subsequent so take note. use ungroup()
  mutate(linenumber = row_number(),
         sentiment = ifelse(is.na(sentiment), 'neutral', sentiment)) %>% 
  ungroup()
  
# Net sentiment ratio by album across time.
lyrics_sentiment <-  tidy_lyrics %>% 
  count(sentiment) %>% 
  spread(key = sentiment, value = n) %>% 
  mutate(sentiment_ratio = (positive - negative) / (positive + negative + neutral)) %>% 
  select(album, year, sentiment_ratio)

lyrics_sentiment %>% ggplot(aes(x = album, y = sentiment_ratio)) + 
  geom_bar(aes(fill = sentiment_ratio < 0), stat = 'identity') +
  geom_text(aes(label = album, hjust = ifelse(sentiment_ratio >= 0, -0.15, 1.15)), vjust = 0.5) +
  scale_fill_manual(guide = FALSE, values = c('#565b63', '#c40909')) +
  scale_y_percent(limits = c(-0.25, 0.05)) +
  coord_flip() +
  theme_ipsum(grid = "X") +
  theme(axis.text.y = element_blank(),
        axis.ticks.y = element_blank())
# needs some work........    why negative? look at HOW negative is defined.
# negative talk but with positive action with negative undertones???? 
# order DESC instead...???


# Most common pos.neg words in THrice lyrics!

word_count <- tidy_lyrics %>% 
  count(word, sentiment, sort = T) %>% 
  ungroup()

top_sentiments <-  word_count %>% 
  filter(sentiment != 'neutral') %>% 
  group_by(sentiment) %>% 
  top_n(6, wt = n) %>% 
  mutate(num = ifelse(sentiment == "negative", -n, n)) %>% 
  mutate(word = reorder(word, num)) %>% 
  select(word, sentiment, num)


ggplot(top_sentiments, aes(x = word, y = num, fill = sentiment)) +
  geom_bar(stat = 'identity') + 
  scale_fill_manual(guide = F, values = c("#af8dc3", "#7fbf7b")) +
  scale_y_continuous(limits = c(-40, 70), breaks = c(-40, -25, -10, 0, 10, 25, 40, 55, 70)) +
  labs(y = "Number of Occurrences",
       x = '',
       title = 'Lyrics Sentiment of Thrice',
       subtitle = 'Most Common Positive and Negative Words') +
  theme_ipsum(grid = "Y") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# Word cloud:
tidy_lyrics %>% 
  filter(sentiment != 'neutral') %>% 
  count(word, sentiment, sort = T) %>% 
  reshape2::acast(word ~ sentiment, value.var = "n", fill = 0) %>% 
  comparison.cloud(colors = c("#af8dc3", "#7fbf7b"))




# Distribution of emotion words BOXPLOT:

emotions_lyrics <- wordToken2 %>% 
  filter(!grepl('[0-9]', word)) %>% 
  left_join(get_sentiments("nrc"), by = "word") %>% 
  filter(!(sentiment == "negative" | sentiment == "positive")) %>% 
  group_by(album, sentiment) %>% 
  summarize(freq = n()) %>% 
  mutate(percent = round(freq / sum(freq)*100)) %>% 
  select(-freq) %>% 
  ungroup() 

emotion_box <- emotions_lyrics %>% 
  spread(sentiment, percent, fill = 0) %>% 
  ungroup()

cols <- colorRampPalette(brewer.pal(7, "Set3"), alpha = T)(8)

boxplot2(emotion_box[ , c(2:9)], col = cols, lty = 1, shrink = 0.8, textcolor = "red", 
         xlab = "Emotion Terms", ylab = "Emotion words count (as %)", 
         main = "Distribution of emotion words count in Thrice lyrics across all albums")

# with bing

emotions_lyrics <- wordToken2 %>% 
  filter(!grepl('[0-9]', word)) %>% 
  left_join(get_sentiments("bing"), by = "word") %>% 
  mutate(sentiment = ifelse(is.na(sentiment), 'neutral', sentiment)) %>%   # if use "bing", need to add in 'neutral' for all NOT pos/neg
  group_by(album, sentiment) %>% 
  summarize(freq = n()) %>% 
  mutate(percent = round(freq / sum(freq)*100)) %>% 
  select(-freq) %>% 
  ungroup() 

# filter(!(sentiment == "negative" | sentiment == "positive")) %>%   
# for nrc use ^
  
emotion_box <- emotions_lyrics %>% 
  spread(sentiment, percent, fill = 0) %>% 
  ungroup()

cols <- colorRampPalette(brewer.pal(7, "Set3"), alpha = T)(8)

boxplot2(emotion_box[ , c(2:4)], col = cols, lty = 1, shrink = 0.8, textcolor = "red", 
         xlab = "Emotion Terms", ylab = "Emotion words count (as %)", 
         main = "Distribution of emotion words count in Thrice lyrics across all albums")



# Pos.Neg words distribution BOXPLOT:
posneg_lyrics <- wordToken2 %>% 
  filter(!grepl('[0-9]', word)) %>% 
  left_join(get_sentiments("bing"), by = "word") %>%          # larger diference when use "bing" vs. "nrc" database! MUST RESEARCH DIFFERENCES!!!!!!!!
  filter((sentiment == "negative" | sentiment == "positive")) %>%    # still filter non-POS/NEG for both
  group_by(album, sentiment) %>% 
  summarize(freq = n()) %>% 
  mutate(percent = round(freq / sum(freq)*100)) %>% 
  select(-freq) %>% 
  ungroup() 


posneg_box <- posneg_lyrics %>% 
  spread(sentiment, percent, fill = 0) %>% 
  ungroup()

boxplot2(posneg_box[ , c(2:3)], col = cols, lty = 1, shrink = 0.8, textcolor = "red", 
         xlab = "Positive or Negative", ylab = "PosNeg/Total (as %)", 
         main = "Distribution of Pos.Neg in Thrice lyrics across all albums")
# bing: categorize binary ONLY POS/NEG
# nrc: categorize ^num of categories POS/NEG/anger/anticipation/disgust/fear/joy/surprise/sadness/trust





# Sentiments Over TIME (or album in this case):
emotions_lyrics <- wordToken2 %>% 
  filter(!grepl('[0-9]', word)) %>% 
  left_join(get_sentiments("bing"), by = "word") %>% 
  mutate(sentiment = ifelse(is.na(sentiment), 'neutral', sentiment)) %>%   # if use "bing", need to add in 'neutral' for all NOT pos/neg
  filter((sentiment == "negative" | sentiment == "positive")) %>%     # filter neutral out comes it screws up the graph lol
  group_by(album, sentiment) %>% 
  summarize(freq = n()) %>% 
  mutate(percent = round(freq / sum(freq)*100)) %>% 
  select(-freq) %>% 
  ungroup() 


# with all the sentiments = use nrc, not ^ code
ggplot(emotions_lyrics, aes(x = album, y = percent, color = sentiment, group = sentiment)) + 
  geom_line(size = 1) + 
  geom_point(size = 3) +
  xlab("Album") + ylab("Emotion Words Count (as %)") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
# Rather messy. no noticeable trends to be found...! ALthough fear has started to creep up after AI:Fire outlier.

# AI: Fire seems to have untrendly amount of FEAR: let's take a closer look!
nrcfear <- get_sentiments("nrc") %>% 
  filter(sentiment == "fear")

wordToken2 %>% 
  filter(album == "The Alchemy Index Fire") %>% 
  inner_join(nrcfear) %>% 
  count(word, sort = TRUE)


# Pos.Neg over TIME (albums):
ggplot(posneg_lyrics, aes(x = album, y = percent, color = sentiment, group = sentiment)) + 
  geom_line(size = 1) + 
  geom_point(size = 3) +
  xlab("Album") + ylab("Emotion Words Count (as %)") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# LOOOOOOOOOOOOOOOOOOOOOOOOOOLLLL 


# Avg. emotion words expressed BAR chart + error:
overall_mean_sd <- emotions_lyrics %>% 
  group_by(sentiment) %>% 
  summarise(overall_mean = mean(percent), sd = sd(percent))

ggplot(overall_mean_sd, aes(x = reorder(sentiment, -overall_mean), y=overall_mean)) +
  geom_bar(stat="identity", fill="darkgreen", alpha=0.7) + 
  geom_errorbar(aes(ymin=overall_mean-sd, ymax=overall_mean+sd), width=0.2,position=position_dodge(.9)) +
  xlab("Emotion Terms") +
  ylab("Emotion words count (%)") +
  ggtitle("Emotion words expressed in Thrice's lyrics") + 
  theme(axis.text.x=element_text(angle=45, hjust=1)) +
  coord_flip( )










# Uni-bi-trigrams
?paste()
nGram <- data_frame(text = paste(wordToken$word, collapse = ' '))
nGramCleaned <- data_frame(text=paste(wordToken2$word, collapse = ' '))

biGrams <-  nGram %>% 
  unnest_tokens(ngram, text, token = "ngrams", n = 2) 

biGramsCleaned <-  nGramCleaned %>% 
  unnest_tokens(ngram, text, token = "ngrams", n = 2) %>%
  count(ngram, sort = TRUE)

triGrams <-  nGram %>% 
  unnest_tokens(ngram, text, token = "ngrams", n = 3) 


biGramsCleaned %>%
  count(ngram, sort = TRUE)

biGramsSep <- biGramsCleaned %>% 
  separate(ngram, c("word1", "word2", sep = " "))


triGrams %>% 
  separate(ngram, c("word1", "word2", "word3"), sep = " ") %>% 
  count(word1, word2, word3, sort = T)

triGrams %>% 
  separate(ngram, c("word1", "word2", "word3"), sep = " ") %>% 
  filter(!word1 %in% stop_words$word,
         !word2 %in% stop_words$word,
         !word3 %in% stop_words$word) %>% 
  count(word1, word2, word3, sort = T)

?top_n

AFINN <- get_sentiments("afinn")

love_words <- biGramsSep %>% 
  filter(word1 == "love") %>% 
  inner_join(AFINN, by = c(word2 = "word")) %>%
  count(word2, score, sort = TRUE) %>%
  ungroup()

love_words %>% 
  mutate(contribution = nn * score) %>% 
  arrange(desc(abs(contribution))) %>% 
  head(20) %>% 
  mutate(word2 = reorder(word2, contribution)) %>% 
  ggplot(aes(word2, nn * score, fill = nn *score > 0)) + 
  geom_col(show.legend = F) +
  coord_flip()

# love betrays, love ... die, love ... evil, love ... chance, love .../ true, love ... loyalty

negation_words <- c("not", "no", "never", "without")

negated_words <- biGramsSep %>%
  filter(word1 %in% negation_words) %>%
  inner_join(AFINN, by = c(word2 = "word")) %>%
  count(word1, word2, score, sort = TRUE) %>%
  ungroup()

medianWord <- median(df$numWord)

uniqueWords <- wordToken2 %>% 
  select(word) %>% 
  filter(!str_detect(word, '[0-9]')) %>% 
  group_by(word) %>% 
  filter(row_number(word) == 1) %>% 
  arrange(word)

numUniqueWords <- nrow(uniqueWords)
numUniqueWords

df %>% 
  ggplot(., aes(x=numWord)) +
  geom_histogram(binwidth=10,
                 color='white',
                 fill='#FCCB85') +
  geom_vline(aes(xintercept=medianWord), colour="#990000", linetype="dashed") +
  coord_cartesian(ylim=c(0, 15)) + 
  scale_y_continuous(breaks=seq(0, 15, 1)) +
  scale_x_continuous(breaks=seq(0, 400, 20)) +
  theme(panel.grid.minor = element_blank()) +
  xlab('Total # of Words') +
  ylab('# of Songs') +
  labs(title='Distribution of Songs by Number of Words', 
       subtitle='Verses repeats not included - Dashed red line is median')


tab <- cbind(countWord, empty, countWord2)

kable(tab[1:20,], format='markdown', row.names = F,
      col.names = c('All uniGrams', 'Freq', ' ', '|', ' ', 'Cleaned uniGrams', 'Freq'))


layout(matrix(c(1,2),1,2, byrow = TRUE))
wordcloud(countWord$word, countWord$n, random.order=FALSE, max.words = 100, 
          colors=brewer.pal(8, "Dark2"), use.r.layout=TRUE)
wordcloud(countWord2$word, countWord2$n, random.order=FALSE, max.words = 100,
          colors=brewer.pal(8, "Dark2"), use.r.layout=TRUE)

# per album:
l <- length(levels(wordToken2$album))
plotList <- list()
for(i in 1:l){
  part <- wordToken2[wordToken2$album == levels(wordToken2$album)[i],] %>%
    group_by(album) %>%
    count(word) %>%
    top_n(10)
  p <- ggplot(part[1:10,], aes(reorder(word,n), n)) +
    geom_bar(stat = "identity", fill='#FCCB85', width=0.65) +
    #        scale_fill_discrete(drop=F) +
    labs(y=NULL, x=NULL, title=paste('Album: ', levels(wordToken2$album)[i], sep='')) +
    coord_flip() +
    theme(plot.title = element_text(size=11))
  plotList[[i]] <- p
}
do.call(grid.arrange, c(plotList, ncol=3))



