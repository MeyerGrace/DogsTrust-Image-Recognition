# Dogs Trust Image Recognition
This is the code that was started in the R-Ladies London Dog Trust Hackathon on 29 September.

We were given images of different dog breeds and asked to classify them as they have many unlabeled images and it would help them operationally to be able to search for images in a better way.

Collaborator: Amy Boyd

## Using Microsoft customvision.ai
Using MS custom vision to classify images from the Dogs Trust Hackathon. https://customvision.ai/

### Manually in the GUI
We first used MS customvision.ai manually through the GUI. You can load the images in and manually tag them and train and test. This was a good first step as a proof of concept.

### Images come from urls
David Smith has an analysis where he uses the customvision API from R called hotdog or notdog code (https://github.com/revodavid/nothotdog) so the process can be automated. The tutorial uses urls and so I did this to get the code working. 

### Images come from the Dogs Trust and are kept as files on the project
being worked on

### Implemention Tips:
I found that when I ran line XX and created the project in the customvision.ai portal that I couldn't see it. I found out that I somehow have two accounts- one linked to my gmail and one to my gmail/microsoft. Once I switched I could see the new project. 

David's code runs a food related project and mine a generic- see here https://docs.microsoft.com/en-us/azure/cognitive-services/custom-vision-service/getting-started-build-a-classifier

Even when testing you need to have at least 5 images per tag.

I used the prediction key from my azure and it worked though it was different to that in the customvision.ai prediction space

## Using Tensor
future goals
