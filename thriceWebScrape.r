# Get lyrics through webscraping!
library(tidytext)
library(stringr)
library(lubridate)
library(purrr)
library(tidyverse)
library(rvest)



# Define list of songs:

base_url <- "https://www.azlyrics.com/lyrics/thrice/"

url <- "https://www.azlyrics.com/lyrics/thrice/"

song_title <- c("brokenlungs", "theskyisfalling", "asongformillymichaelson")

url <- paste0(url, song_title, ".html")
url

page <- url %>%
  read_html() %>% 
  html_nodes("div") %>% 
  .[[22]] %>% 
  html_text()
  

library(purrr)

base_url <- "https://www.azlyrics.com/lyrics/thrice/"
song_title <- c("brokenlungs", "theskyisfalling", "asongformillymichaelson")
end_url <- paste0(song_title, ".html")

end_url

map_df(end_url, function(i) {
 
 pg <- read_html(paste0(base_url, i)) 
 
 tibble(
   title <- pg %>%  
     html_nodes("b") %>% 
     html_text(),
   lyrics <- pg %>% 
     html_nodes("div.col-xs-12:nth-child(2) > div:nth-child(8)") %>% 
     html_text()
     )
  
})



# for loop ----------------------------------------------------------------

base_url <- "https://www.azlyrics.com/lyrics/thrice/"

song_title <- c("brokenlungs", "theskyisfalling", "asongformillymichaelson")

url <- paste0(base_url, song_title, ".html")

url

out <- vector("character", length = length(url)) 

for(i in seq_along(url)){
  page <- read_html(url[i])
  out[i] <- page %>% 
    html_node("div.col-xs-12:nth-child(2) > div:nth-child(8)") %>% 
    html_text()
}

out

df_out <- as.data.frame(matrix(out, nrow = 3))

df_out <- df_out %>% cbind(song_title)



#### individually ####

read_html("https://www.azlyrics.com/lyrics/thrice/identitycrisis.html") %>% 
  html_nodes("div") %>% 
  .[[22]] %>% 
  html_text()

read_html("https://www.azlyrics.com/lyrics/thrice/phoenixignition.html") %>% 
  html_nodes("div") %>% 
  .[[22]] %>% 
  html_text()

read_html("https://www.azlyrics.com/lyrics/thrice/whistleblower.html") %>% 
  html_nodes("div") %>% 
  .[[22]] %>% 
  html_text()


"div.col-xs-12:nth-child(2) > div:nth-child(8)"

read_html("https://www.azlyrics.com/lyrics/thrice/whistleblower.html") %>% 
  html_nodes("div.col-xs-12:nth-child(2) > div:nth-child(8)") %>% 
  html_text()

#









# scrape lyrics names:
thriceNameUrl <- "http://www.azlyrics.com/t/thrice.html"

thriceName <- thriceNameUrl %>% 
  read_html() %>% 
  html_nodes("listAlbum") %>% 
  html_text()

thriceName <- thriceNameUrl %>% 
  read_html() %>% 
  html_nodes("listAlbum") %>% 
  html_attr("href")

thriceName

??html_attr()

# try html_attr()??

#listAlbum > a:nth-child(4)
#listAlbum
#listAlbum > a:nth-child(2)
#listAlbum
# div.album:nth-child(2)
#\31 4286#\31 4286
#listAlbumdiv.album:nth-child(2)
#listAlbum
thriceName

# Clean poem names:
thriceName <- thriceName %>% 
  str_replace_all(pattern = "\r", replacement = "") %>% 
  str_replace_all(pattern = "\n", replacement = " ") %>% 
  str_replace_all(pattern = "[  ]{2}", replacement = "") %>% 
  str_replace_all(pattern = "[[:punct:]]", replacement = "") %>% 
  tolower()

head(poemName)
poemName[9] <- "he mourns for the change"
poemName[24] <- "the old men admiring themselves"

head(poemName, 24)

# scrape poems and dates:
nameVec <- unlist(str_split(poemName, pattern = " "))
nameVec


url <- "http://www.poetry-archive.com/y/at_galway_races.html"
date <-  url %>%
  read_html() %>%
  html_nodes("td font") %>%
  html_text()

date[1]
date[2]
date[3]
date[3] %>% str_extract(pattern = "[0-9]+")
date[1] %>% str_replace_all(pattern = "\r", replacement = "") %>% 
  str_replace_all(pattern = "\n", replacement = " ") %>% 
  tolower()

### Function across multiple Lyrics Pages

getThriceLyrics <- function(poemName) {
  # split string at empty space and unlist the result  
  nameVec <- unlist(str_split(poemName, pattern = " "))
  
  # use result in url 
  url <- str_c("http://www.poetry-archive.com/y/", 
               paste(nameVec, collapse = "_"),
               ".html") 
  
  # scrape for poem and clean
  poem <- url %>%
    read_html() %>%
    html_nodes("dl") %>%
    html_text() %>%
    str_replace_all(pattern = "\r", replacement = "") %>%
    str_replace_all(pattern = "\n", replacement = " ") %>%
    str_replace_all(pattern = "[  ]{2}", replacement = "")
  
  # scrape for date 
  date <- url %>%
    read_html() %>%
    html_nodes("td font") %>%
    html_text() 
  
  # clean dates
  date <- date[3] %>%
    str_extract(pattern = "[0-9]+")
  
  # pause before function return
  Sys.sleep(runif(1, 0, 1))
  
  return(list(poem = poem, date = date))
}