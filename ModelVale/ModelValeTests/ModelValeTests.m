//
//  ModelValeTests.m
//  ModelValeTests
//
//  Created by Chaytan Inman on 7/3/22.
//

#import <XCTest/XCTest.h>
#import "DataViewController.h"
#import "ModelLabel.h"
#import "ModelData.h"

@interface ModelValeTests : XCTestCase
@property (nonatomic, strong) DataViewController* dvc;
@end

@implementation ModelValeTests

- (void)setUp {
    self.dvc = [DataViewController new];
    self.dvc.modelLabels = [NSMutableArray new];

    // First section has two datapoints, second section has one
    // Add two mountains to label "mountain" and add to dvc
    ModelLabel* fakeLabel = [[ModelLabel new] initEmptyLabel:@"mountain" testTrainType:Train];
    UIImage* testImage = [UIImage imageNamed:@"mountain"];
    ModelData* fakeData = [[ModelData new] initWithImage:testImage label:fakeLabel]; // Note: adds itself to the label passed
    testImage = [UIImage imageNamed:@"rivermountain"];
    fakeData = [[ModelData new] initWithImage:testImage label:fakeLabel];
    [self.dvc.modelLabels addObject:fakeLabel];
    // Add one mountain to the label "hill" and add to dvc
    fakeLabel = [[ModelLabel new] initEmptyLabel:@"hill" testTrainType:Train];
    testImage = [UIImage imageNamed:@"snowymountains"];
    fakeData = [[ModelData new] initWithImage:testImage label:fakeLabel];
    [self.dvc.modelLabels addObject:fakeLabel];
    assert(self.dvc.modelLabels.count == 2);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGetSection {

    NSArray* ret = [self.dvc getSectionFromRow:2]; // indexPath.row = 2 (3rd thing since we index at 0)
    NSInteger section = [((NSNumber*) ret[0]) integerValue];
    NSInteger dataBefore = [((NSNumber*) ret[1]) integerValue];
    XCTAssertEqual(1, section); // Given our setup with three total images and two in the 0th section, should be section 1
    XCTAssertEqual(2, dataBefore); // Given that we saw two images in the section before, this should be 2
    
    ret = [self.dvc getSectionFromRow:0];
    section = [((NSNumber*) ret[0]) integerValue];
    dataBefore = [((NSNumber*) ret[1]) integerValue];
    XCTAssertEqual(0, section);
    XCTAssertEqual(0, dataBefore);
    
    ret = [self.dvc getSectionFromRow:1];
    section = [((NSNumber*) ret[0]) integerValue];
    dataBefore = [((NSNumber*) ret[1]) integerValue];
    XCTAssertEqual(0, section);
    XCTAssertEqual(0, dataBefore);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
