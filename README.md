# ModelVale README
![Artboard 1180](https://user-images.githubusercontent.com/35582442/183337152-4fead59c-55df-4060-aa0b-8c1bd06ecada.png)
## Overview
### [Demo](https://recordit.co/wproHGzuGB)

### Description
Modelvale is an app designed to bring machine learning to life. Each model is represented by an avatar with a dynamic health bar representing the overall model's performance. For instance, with a model classifying objects (e.g. if there is a picture of a dog, it will predict the label "dog"), the health bar fills when the model correctly classifies an object, decreases when more computation is used to train it, and more. Over time you can see your best performing models and their attributes, and keep training and testing their predictions to keep up their health.

## 1. User Stories (Required and Optional)

**Required Must-have Stories**
* Sign in and register with Modelvale account
     * User persistence
 * Unique avatars to represent each user's model(s)
     * Uses CoreML to package models and be able to use them for predictions and retraining
 * Health bar of the model to represent overall performance **Technical Problem**
     * Base off of correct to incorrect prediction ratio
     * Time slowly decreases health
     * Training computational resources drains health
     * Larger model size drains health
     * Is a comparable, meaningful metric across disparate models (i.e. the health bar is one way to compare how "well" an image classifier is doing vs a object detection model, vs other different types)
 * User uploads or provides dataset link to data to test the model on
 * User can retrain pretrained model using immediate data
     * Photos from camera or camera roll (convolutional networks)
     * Other: Sound? Video? Text?
 * User can upload a new pretrained model
 * Animation of the health bar as it increases or decreases after testing **Technical Problem**
 * Sign out of the app

**Optional Nice-to-have Stories**

*  Background music and improved avatar aesthetics
 * Visualize training process and important weights in network
 * Models can mutate their structures and create new models
     * Genetic algorithm over autoencoder latent layer of source code of models
 * Display GPT-3 performance and baseline, non-NN models like linear regression, random forest
 * Have multiple avatars at once
 * Model leaderboards
 * In-game achievements
 *  See stats about best performing models across time
     *  This uses a database backend like Parse or Firebase to store preferences
 *  Push notifications about model performance
 
 **Other Possible Technical Problems**
 * Planning for very large datasets and fetching in chunks to display data
 * Use multithreading and progress bars to retrain models in the background

## 2. Screen Archetypes

* Launch view
* Welcome view
 * Login view
* Registration view
 * Model avatars view
* Data Management view
* Testing view
* Retraining view

## 3. Navigation

Optional:
- Achievements
- Leaderboard
- Stats

**Flow Navigation** (Screen to Screen)

 * Launch
 * Welcome
 * Login
 * Registration
 * All Models
 * Data Management
 * Testing
 * Training

## Wireframes
![IMG_0060](https://user-images.githubusercontent.com/35582442/177838999-1dac750c-efb7-4ad6-95c6-6cedf4e2cd83.JPG)

## Query Efficiency, Database Design Diagram
![IMG_0148](https://user-images.githubusercontent.com/35582442/183224771-aa3d47e6-fd99-4158-aedf-049efc9ed062.JPG)

## Weekly Milestones

**Week 1, July 04**
* Build UI wireframes and skeleton
* Midpoint review
* Test crucial assumptions
    * Import model with CoreML
    * Test retraining feature with CoreML

**Week 2, July 11**
* Finish login code and UI design + code
* Calculate and display model stats
* Calculating model health bar algorithm

**Week 3, July 18**
* Database code
    * Save stats of models for each user
* User retraining of model with CoreML
    * Use user captured data, photos
* Add healthbar animation and xp animations.

**Week 4, July 25**
* Database code
    * Investigate, test and debug wich database platform is better for the application context(Firebase or Parse).
    * Create the boilerplate in the the selected platform admin page.
    * Crate boilerplate code in the iOS client application.
    * Implement CRUD actions in the iOS app to the selected platform.
   
**Week 5, August 01**
* Final self review
* Fetch and display Firebase data for all screens
* Paginate data queries or design queries for scale of millions of images
* Add multiple models
* Add health bar calculations
    
**Week 6, August 08**
* Finish app
* Polish
* Create demonstrations
* Demo finished app
    
**Week 7, August 15**
* Offboarding, wrap up
