//
//  TestTrainEnum.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/12/22.
//

#import <Foundation/Foundation.h>
#import "TestTrainEnum.h"

// https://stackoverflow.com/questions/13171907/best-way-to-enum-nsstring
NSString* dataTypeEnumToString(testTrain enumVal) {
    NSArray *dataTypeArray = [[NSArray alloc] initWithObjects:testTrainTypeArray];
    return [dataTypeArray objectAtIndex:enumVal];
}

// A method to retrieve the int value from the NSArray of NSStrings
testTrain dataTypeStringToEnum(NSString* strVal) {
    NSArray *dataTypeArray = [[NSArray alloc] initWithObjects:testTrainTypeArray];
    NSUInteger n = [dataTypeArray indexOfObject:strVal];
    if(n < 1) n = Test;
    return (testTrain) n;
}
