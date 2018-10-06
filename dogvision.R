## use the custom vision API to create a function that identifies
## whether an image on the web is a hotdog or not

## You can see the effects of your API calls as you go by browsing to
## https://www.customvision.ai/projects and logging in with your Microsoft Account

## Overview
## https://docs.microsoft.com/en-us/azure/cognitive-services/custom-vision-service/home

## training API reference
## https://southcentralus.dev.cognitive.microsoft.com/docs/services/fde264b7c0e94a529a0ad6d26550a761/operations/59568ae208fa5e09ecb9983a
## prediction API reference:
## https://southcentralus.dev.cognitive.microsoft.com/docs/services/57982f59b5964e36841e22dfbfe78fc1/operations/5a3044f608fa5e06b890f164

library(httr)
library(jsonlite)
setwd("~/GitHub/image-recognition-MS-CVai")

## Read in a file of URLs of images of pugs, and also a file of grey hounds
## The URLs were sourced on 6 October 2018, but since then a few URLs have started
## if in the future urls to fail or return thumbnail "errors", so a manual review will be necessary (see below).
pug <- scan("pug.txt",what = character())
greyhound <- scan("greyhound.txt", what = character())

## NOTE: We created the files pug-good.txt and greyhound-good.txt
## using ImageNet data and some visual inspection. See the file
## greyhound-find-data.R if you want to see how it was done.

## Retrieve API keys from keys.txt file, set API endpoint
keys <- read.table("keys.txt", header = TRUE, stringsAsFactors = FALSE)

## Check to see if the default keys.txt file is still there
region <- keys["region", 1]
if (region == "ERROR-EDIT-KEYS.txt-FILE") {
 stop("Edit the file keys.txt to provide valid keys. See README.md for details.")
}

## retrieve custom vision key
cvision_api_key <- keys["custom",1]
cvision_api_endpoint <- "https://southcentralus.api.cognitive.microsoft.com/customvision/v1.1/Training"

## Get the list of available training domains
domainsURL <- paste0(cvision_api_endpoint, "/domains")

APIresponse = GET(url = domainsURL,
                   content_type_json(),
                   add_headers(.headers = c('Training-key' = cvision_api_key)),
                   body = "",
                   encode = "json")

domains <- content(APIresponse)
domains.Generic <- domains[[1]]$Id #this is where I select the generic domain

## Create a project
createURL <- paste0(cvision_api_endpoint, "/projects?",
                    "name=dogstrust2app&",
                    'description=dogstrust2&',
                    'domainId=',
                    domains.Generic)

APIresponse = POST(url = createURL,
                   content_type_json(),
                   add_headers(.headers = c('Training-key' = cvision_api_key)),
                   body = "",
                   encode = "json")

cvision_id <- content(APIresponse)$Id

## Next, create tags we will use to label the images
## We will use "hotdog" for hot dog images and "greyhound" for similar looking foods
## We will save the tag ids returned by the API for use later

## function to create one tag, and return its id
createTag <- function(id, tagname) {
 eURL <- paste0(cvision_api_endpoint, "/projects/", id, "/tags?",
                "name=",tagname)

 APIresponse = POST(url = eURL,
                    content_type_json(),
                    add_headers(.headers= c('Training-key' = cvision_api_key)),
                    body="",
                    encode="json")

 content(APIresponse)$Id
}

pug_tag <- createTag(cvision_id, "pug")
greyhound_tag <- createTag(cvision_id, "greyhound")
tags <- c(pug = pug_tag, greyhound = greyhound_tag)

## Upload images to Custom Vision. We will cycle through lists of URLs
## provided in the txt files

uploadURLs <- function(id, tagname, urls) {
 ## id: Project ID
 ## tagname: one tag (applued to all URLs), as a tag ID
 ## urls: vector of image URLs

 eURL <- paste0(cvision_api_endpoint, "/projects/", id, "/images/url")
 success <- logical(0)

 ## The API accepts 64 URLs at a time, max, so:
 while(length(urls) > 0) {

  N <- min(length(urls), 64)
  urls.body <- toJSON(list(TagIds=tagname, Urls=urls[1:N]))

  APIresponse = POST(url = eURL,
                    content_type_json(),
                    add_headers(.headers= c('Training-key' = cvision_api_key)),
                    body=urls.body,
                    encode="json")

  success <- c(success,content(APIresponse)$IsBatchSuccessful)
  urls <- urls[-(1:N)]
 }
 all(success)
}

uploadURLs(cvision_id, tags["pug"], pug)
uploadURLs(cvision_id, tags["greyhound"], greyhound)

## If either of the calls above returned FALSE, that means at least one image
## couldn't be uploaded. This is most likely due to a bad URL, and the
## issue can safely be ignored. It just means you'll have fewer images to train with.

## If you want to review the images you've uploaded,
## this is a good time to visit https://customvision.ai
## Log in using the same Azure account you used to generate the keys,
## browse to your project and click the "Training Images" tab.
## There, you can review the uploaded images and delete images or adjust
## tags as needed.

## Get status of projects
projURL <- paste0(cvision_api_endpoint, "/projects/")

APIresponse = GET(url = projURL,
                   content_type_json(),
                   add_headers(.headers = c('Training-key' = cvision_api_key)),
                   body = "",
                   encode = "json")

projStatus <- content(APIresponse)

print(projStatus[[1]]$Id)
print(cvision_id) # should be the same, if you've just trained the model

## Train project
trainURL <- paste0(cvision_api_endpoint, "/projects/",
                   cvision_id,
                   "/train")

APIresponse = POST(url = trainURL,
                   content_type_json(),
                   add_headers(.headers =  c('Training-key' = cvision_api_key)),
                   body = "",
                   encode = "json")

train.id <- content(APIresponse)$Id

## Function to check status of a trained model (iteration)

iterStatus <- function(id) {
 iterURL <- paste0(cvision_api_endpoint, "/projects/",
                    cvision_id,
                    "/iterations/",
                    id)

 APIresponse = GET(url = iterURL,
                    content_type_json(),
                    add_headers(.headers = c('Training-key' = cvision_api_key)),
                    body = "",
                    encode = "json")

 content(APIresponse)$Status
}

## Training is asynchronous. Check until the status is "Completed"
iterStatus(train.id)

## Next, let's create some predictions from our model.
## For this next part, you will need to your prediction key, which was created
## for you

## You can also retrieve your prediction key from the customvision.ai service, as follows:
## 1. Visit https://customvision.ai
## 2. Click "Sign In"
## 3. Wait for projects to load, and then click your project
## 4. Click on Performance. Here you can check the precision and recall of your trained model.
## 5. Click on Prediction URL, and look at the "If you have an image URL" section
## 6. Check that the URL in the gray box matches cvision_api_endpoint_pred, below
## 7. Copy the key listed by "Set Prediction-Key Header to:" to cvision_pred_key below

## With your prediction key in the keys.txt file we imported earlier,
## store the prediction key in cvision_api_endpoint_pred:
cvision_api_endpoint_pred <- "https://southcentralus.api.cognitive.microsoft.com/customvision/v1.1/Prediction"
cvision_pred_key <- keys["cvpred", 1]

## Function to generate predictions

dog_predict <- function(imageURL, threshold = 0.5) {
 predURL <- paste0(cvision_api_endpoint_pred, "/", cvision_id,"/url?",
                   "iterationId=",train.id,
                   "&application=R"
                   )

 body.pred <- toJSON(list(Url = imageURL[1]), auto_unbox = TRUE)

 APIresponse = POST(url = predURL,
                    content_type_json(),
                    add_headers(.headers= c('Prediction-key' = cvision_pred_key)),
                    body = body.pred,
                    encode = "json")

 out <- content(APIresponse)

 if (!is.null(out$Code)) msg <- paste0("Can't analyze: ", out$Message) else
 {
  predmat <- matrix(unlist(out$Predictions), nrow = 3)
  preds <- as.numeric(predmat[3,])
  names(preds) <- predmat[2,]

  ## uncomment this to see the class predictions
  ## print(preds)

  if (preds["pug"] > threshold) msg <- "Pug" else
   if (preds["greyhound"] > threshold) msg <- "Greyhound" else
    msg <- "Don't know"
  }

  names(msg) <- imageURL[1]
  msg
}

dog_predict(pug[1])
dog_predict(greyhound[1])

## here are some images to try, from a Google Image Search for "hotdog
example.pug <- scan("train_pug.txt",what = character())
example.greyhound <- scan("train_greyhound.txt",what = character())

dog_predict(example.pug[1])
dog_predict(example.greyhound[1])

for (i in 1:length(example.pug)) {
  print(dog_predict(example.pug[i]))
}

for (i in 1:length(example.greyhound)) {
  print(dog_predict(example.greyhound[i]))
}

## Here's an example where the classification is wrong, at the 50% threshold
#hotdog_predict(example.greyhound[4]) #I guess here I make sure that there is

## We can be more conservative, at the expense of misclassifying some actual pug
dog_predict(example.greyhound[2], threshold = 0.70)
dog_predict(example.pug[2], threshold = 0.7)



