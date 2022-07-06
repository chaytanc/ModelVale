# README
Modelvale

## Overview
### Description
Modelvale is an app designed to bring machine learning to life. Each model is represented by an avatar with a dynamic health bar representing the overall model's performance. For instance, with a model classifying objects (e.g. if there is a picture of a dog, it will predict the label "dog"), the health bar can fill when the model correctly classifies an object, can decrease when more computation is used to train it, and more. When models die, you can choose to respawn it or start with a new model, and over time you can see the best performing models and their attributes!

## 1. User Stories (Required and Optional)

**Required Must-have Stories**
* Sign in and register with Modelvale account
     * User persistence
 * Unique avatars to represent each user's model(s)
     * Uses CoreML to package models and be able to use them for predictions and retraining
 * Health bar of the model to represent overall performance
     * Base off of correct to incorrect prediction ratio
     * Time slowly decreases health
     * Training computational resources drains health
     * Larger model size drains health

 * User uploads or provides dataset link to data to test the model on
 *  See stats about best performing models across time
     *  This uses a database backend like Parse or Firebase to store preferences
 *  Push notifications about model performance
 * User can retrain pretrained model using immediate data
     * Photos from camera or camera roll (convolutional networks)
     * Copy pasted text (NLP models)
     * Other: Sound? Video?
 * User can upload a new pretrained model
 * One animation of some view
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

## 2. Screen Archetypes

* Launch view
* Welcome view
 * Login view
* Registration view
 * Model avatars view
* Stats view

## 3. Navigation

**Tab Navigation** (Tab to Screen)

 * Stats
 * All Models
 * Model Details

Optional:
- Achievements
- Leaderboard

**Flow Navigation** (Screen to Screen)

 * Launch
 * Welcome
 * Login
 * Registration
 * All Models

## Wireframes
![](https://i.imgur.com/xzrqHVP.jpg)


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

**Week 4, July 25**
* Improve avatars of models
* Uploading new models
* Start stretch features if ready
    
**Week 5, August 01**
* Get feedback from Taylor and David, review and revise
* Self review
* Stretch features like improved aesthetics, avatars, gameification, animations, achievements
    
**Week 6, August 08**
* Finish app
* Polish
* Create demonstrations
    
**Week 7, August 15**
* Offboarding, wrap up
