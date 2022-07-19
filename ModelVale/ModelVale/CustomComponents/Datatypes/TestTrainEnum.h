//
//  TestTrainEnum.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#ifndef TestTrainEnum_h
#define TestTrainEnum_h


#endif /* TestTrainEnum_h */
//
typedef enum {
    Test,
    Train,
} testTrain;

#define testTrainTypeArray [NSArray arrayWithObjects:@"Test", @"Train", nil]

NSString *dataTypeEnumToString(testTrain enumVal);
//
testTrain dataTypeStringToEnum(NSString* strVal);

