# image-recognition-MS-CVai
Using MS custom vision to classify images from the Dogs Trust Hackathon

This is the code that was started in the R-Ladies London Dog Trust Hackathon on 29 September.

We were given images of different dog breeds and asked to classify them as they have many unlabeled images and it would help them operationally to be able to search for images in a better way.

Amy Boyd and I worked on using MS customvision.ai manually through the GUI and then using David Smith's hotdog or notdog code from EARL (https://github.com/revodavid/nothotdog) to try and automate this process.

Tips:
I found that when I ran line XX and created the project in the customvision.ai portal that I couldn't see it. I found out that I somehow have two accounts- one linked to my gmail and one to my gmail/microsoft. Once I switched I could see the new project. 

David's code runs a food related project and mine a generic- see here https://docs.microsoft.com/en-us/azure/cognitive-services/custom-vision-service/getting-started-build-a-classifier

Even when testing you need to have at least 5 images per tag.

I used the prediction key from my azure and it worked though it was different to that in the customvision.ai prediction space

