//
//  TestTrainEnum.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/12/22.
//

#import <Foundation/Foundation.h>
#import "TestTrainEnum.h"

NSString* dataTypeEnumToString(testTrain enumVal) {
    NSArray *dataTypeArray = [[NSArray alloc] initWithObjects:testTrainTypeArray];
    return [dataTypeArray objectAtIndex:enumVal];
}
