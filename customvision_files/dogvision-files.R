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

library(httr)
library(jsonlite)
library(dplyr)
setwd("~/GitHub/image-recognition-MS-CVai")

#breeds and location of files
breedClasses <- c("greyhound", "pug")
pugTrain <- "customvision_files/pug"
greyhoundTrain <- "customvision_files/greyhound"


## Retrieve API keys from keys.txt file, set API endpoint
keys <- read.table("keys.txt", header = TRUE, stringsAsFactors = FALSE)

## Check to see if the default keys.txt file is still there
region <- keys["region", 1]
if (region == "ERROR-EDIT-KEYS.txt-FILE") {
  stop("Edit the file keys.txt to provide valid keys. See David's README.md for details.")
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
                    "name=DogFilesImages&",
                    'description=DogFilesImages&',
                    'domainId=',
                    domains.Generic)

APIresponse = POST(url = createURL,
                   content_type_json(),
                   add_headers(.headers = c('Training-key' = cvision_api_key)),
                   body = "",
                   encode = "json")

cvision_id <- content(APIresponse)$Id

## Next, create tags we will use to label the images
## We will use "pug" for pug images and "greyhound" for greyhound images
## We will save the tag ids returned by the API for use later

## function to create one tag, and return its id
createTag <- function(id, tagname) {
  eURL <- paste0(cvision_api_endpoint, "/projects/", id, "/tags?",
                 "name=",tagname)

  APIresponse = POST(url = eURL,
                     content_type_json(),
                     add_headers(.headers = c('Training-key' = cvision_api_key)),
                     body = "",
                     encode = "json")

  content(APIresponse)$Id
}


tags <- as.vector(0)
for (i in 1:length(breedClasses)) {
  #assign(paste0(i, "_tag"), createTag(projectid,i))
  tag_i <- breedClasses[i]
  tag_i
  tags[i] <- createTag(cvision_id, tag_i)
  tags[i]

}
names(tags) <- breedClasses

# this is how you do it separately
# pug_tag <- createTag(cvision_id, "pug")
# greyhound_tag <- createTag(cvision_id, "greyhound")
# tags <- c(pug = pug_tag, greyhound = greyhound_tag)

## Upload images to Custom Vision. We will cycle through a folder of image files

uploadFiles <- function(id, tagname, files) {
  ## id: Project ID
  ## tagname: one tag (applued to all URLs), as a tag ID
  ## files: vector of image URLs

  eFiles <- paste0(cvision_api_endpoint, "/projects/", id, "/images/files")
  success <- logical(0)

  ## The API accepts 64 URLs at a time, max, so:
  while (length(files) > 0) {

    N <- min(length(files), 64)
    files.body <- toJSON(list(TagIds = tagname, images = files[1:N]))

    APIresponse = POST(url = eFiles,
                       content_type_json(),
                       add_headers(.headers = c('Training-key' = cvision_api_key)),
                       body = files.body,
                       encode = "json")

    success <- c(success,content(APIresponse)$IsBatchSuccessful)
    files <- files[-(1:N)]
  }
  all(success)
}

#try for one image
uploadFiles(cvision_id, tags["greyhound"], "customvision_files/greyhound/Greyhound (42).png")


# for (i in breedClasses) {
#   uploadURLs(cvision_id, tags[i], eval(parse(text = paste0(i,"Train"))))
# }

#how to do it one by one
# uploadURLs(cvision_id, tags["pug"], pugTrain)
# uploadURLs(cvision_id, tags["greyhound"], greyhoundTrain)

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

breed_predict <- function(imageURL, threshold = 0.5) {
  predURL <- paste0(cvision_api_endpoint_pred, "/", cvision_id, "/url?",
                    "iterationId=", train.id,
                    "&application=R"
  )

  body.pred <- toJSON(list(Url = imageURL[1]), auto_unbox = TRUE)

  APIresponse = POST(url = predURL,
                     content_type_json(),
                     add_headers(.headers = c('Prediction-key' = cvision_pred_key)),
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

    if (max(preds) > threshold) {
      msg <- names(preds)[which(preds == max(preds))]
    } else {
      msg <- "Unsure"
    }

    # if (preds["pug"] > threshold) msg <- "Pug" else
    #  if (preds["greyhound"] > threshold) msg <- "Greyhound" else
    #   msg <- "Don't know"
  }

  msg <- c(imageURL[1], msg, max(preds))
  return(msg)
}

breed_predict(pugTrain[1])
breed_predict(greyhoundTrain[1])

breed_predict(pugTest[1])
breed_predict(greyhoundTest[1])

for (i in 1:length(pugTest)) {
  print(breed_predict(pugTest[i]))
}

for (i in 1:length(greyhoundTest)) {
  print(breed_predict(greyhoundTest[i]))
}

testResults <- data.frame(label = "A",
                          url = "A",
                          prediction = "A",
                          probability = "A",
                          stringsAsFactors = FALSE)
for (i in breedClasses) {
  #print(i)
  testUrls <- eval(parse(text = paste0(i,"Test")))
  #print(testUrls)
  for (j in testUrls) {
    #print(j)
    testPred <- breed_predict(j)
    Sys.sleep(5)
    #print(testPred)
    testPred <- c(i, testPred)
    #print(testPred)
    testResults <- rbind(testResults, testPred)
    #print(testResults)
  }
}

testResults <- testResults[-1, ]

accuracy <- mean(testResults$label == testResults$prediction)

## David has examples where the  classification is wrong, at the 50% threshold
#so you can bump up the threshold to be higher

## We can be more conservative, at the expense of misclassifying some actual pug
breed_predict(greyhoundTest[2], threshold = 0.70)
breed_predict(pugTest[2], threshold = 0.7)



