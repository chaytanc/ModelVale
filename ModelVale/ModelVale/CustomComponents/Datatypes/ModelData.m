//
//  User.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import "ModelData.h"

@implementation ModelData

- (ModelData*) initWithImage:(UIImage *)image label:(ModelLabel *)label {
    self.image = image;
    // Update reference within data to the label and then update the label's labelModelData list with the new datapoint
    self.label = label;
    [label addLabelModelData:@[self]];
    return self;
}

@end
