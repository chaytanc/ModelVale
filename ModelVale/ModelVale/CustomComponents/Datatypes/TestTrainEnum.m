//
//  TestTrainEnum.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/12/22.
//

#import <Foundation/Foundation.h>
#import "TestTrainEnum.h"

NSString* dataTypeEnumToString(testTrain enumVal) {
    NSArray *dataTypeArray = testTrainTypeArray;
    return [dataTypeArray objectAtIndex:enumVal];
}

// A method to retrieve the int value from the NSArray of NSStrings
testTrain dataTypeStringToEnum(NSString* strVal) {
    NSArray* dataTypeArray = testTrainTypeArray;
    NSUInteger n = [dataTypeArray indexOfObject:strVal];
    if(n < 1) {
        n = Test;
    }
    return (testTrain) n;
}
