## use the custom vision API to create a function that identifies
## the breed of dog of an image given by the dogs trust

## You can see the effects of your API calls as you go by browsing to
## https://www.customvision.ai/projects and logging in with your Microsoft Account

## Overview
## https://docs.microsoft.com/en-us/azure/cognitive-services/custom-vision-service/home

## training API reference
## https://southcentralus.dev.cognitive.microsoft.com/docs/services/fde264b7c0e94a529a0ad6d26550a761/operations/59568ae208fa5e09ecb9983a
## prediction API reference:
## https://southcentralus.dev.cognitive.microsoft.com/docs/services/57982f59b5964e36841e22dfbfe78fc1/operations/5a3044f608fa5e06b890f164

#### load packages
library(httr)
library(jsonlite)
library(caret)
library(dplyr)
library(purrr)


## Retrieve API keys from keys.txt file, set API endpoint
keys <- read.table("keys.txt", header = TRUE, stringsAsFactors = FALSE)

# trainingkey <- "2984770d07e24008bf2166cf9fd5cd89"
# predictionkey <- "69aad4e0a3d4480f89083c9a6231d4c0"
# projectid <- "c344a52e-ca2c-4be1-b954-588c59e4ded6"



#Data Processing - train/test split
fileNames <- list.files("DogPhotos")

breeds <- gsub(" ", "", fileNames)
breeds <- gsub("\\(.*","", breeds)


head(breeds)
sort(table(breeds))
length(unique(breeds))

#create a train and test set
dogDF <- data.frame(fileName = fileNames, breed = breeds)

trainSplit <- createDataPartition(dogDF$breed, p = 0.8, list = FALSE)
trainSplit <- trainSplit[ , 1] #just need a vector
trainFiles <- dogDF$fileName[trainSplit]
testFiles <- dogDF$fileName[-trainSplit]

dogDF <- dogDF %>%
  mutate(train = fileName %in% trainFiles)



file.copy(paste0("DogPhotos/", trainFiles), paste0("train/", trainFiles), overwrite= TRUE)
file.copy(paste0("DogPhotos/", testFiles), paste0("test/", testFiles), overwrite = TRUE)

cvision_api_endpoint <- "https://southcentralus.api.cognitive.microsoft.com/customvision/v2.0/Training"

## function to create one tag, and return its id
createTag <- function(id, tagname) {
 eURL <- paste0(cvision_api_endpoint, "/projects/", id, "/tags?",
                "name=",tagname)

 APIresponse = POST(url = eURL,
                    content_type_json(),
                    add_headers(.headers= c('Training-key' = trainingkey)),
                    body="",
                    encode="json")

 content(APIresponse)$Id
}

classes <- unique(breeds)
classes

tags <- as.vector(0)
print(length(classes))
for(i in 1:length(classes)){
    #assign(paste0(i, "_tag"), createTag(projectid,i))
    tag_i <- classes[i]
    print(tag_i)
    tags[i] <- createTag(projectid, tag_i)
    print(tags[i])

}
names(tags) <- classes




tags

AkitaFiles <- trainFiles[grep("Akita", trainFiles)]
AkitaFiles <- as.character(paste0("train/", AkitaFiles))


#AkitaFiles <- scan("nothotdog/hotdogs-good.txt",what=character())
AkitaFiles

## Upload images to Custom Vision. We will cycle through lists of image files

uploadFiles <- function(id, tagname, files) {
 ## id: Project ID
 ## tagname: one tag (applued to all URLs), as a tag ID
 ## files: vector of file locations/names

 eURL <- paste0(cvision_api_endpoint, "/projects/", id, "/images/files")
 print(eURL)
# url from: https://southcentralus.dev.cognitive.microsoft.com/docs/services/d0e77c63c39c4259a298830c15188310/operations/5a59953940d86a0f3c7a8286
 success <- logical(0)
print(success)


 ## The API accepts 64 files at a time, max, so:
 while(length(files) > 0) {

  N <- min(length(files), 64)
  print(N)
  files.body <- toJSON(list(TagIds=tagname, Files=files[1:N]))
  print(files.body)

  APIresponse = POST(url = eURL,
                    #content_type_json(),
                    add_headers(.headers= c('Training-key' = trainingkey)),
                    body=files.body
                    #encode="json")
                     )

    print(APIresponse)
     print(content(APIresponse))

  success <- c(success,content(APIresponse)$IsBatchSuccessful)
  files <- files[-(1:N)]
 }
 all(success)
}



uploadFiles(projectid, tags["Akita"], AkitaFiles)
#uploadURLs(cvision_id, tags["nothotdog"], nothotdogs)

list.files("train/")
